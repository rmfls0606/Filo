//
//  DetailViewModel.swift
//  Filo
//
//  Created by 이상민 on 1/25/26.
//

import UIKit
import RxSwift
import RxCocoa

final class DetailViewModel: ViewModelType {
    private let disposeBag = DisposeBag()
    
    private let filterIdRelay: BehaviorRelay<String>
    private let externalFilterValuesRelay = PublishRelay<FilterValuesDTO>()
    
    init(filterId: String) {
        self.filterIdRelay = BehaviorRelay(value: filterId)
    }

    func updateFilterValues(_ values: FilterValuesDTO) {
        externalFilterValuesRelay.accept(values)
    }
    
    struct Input{
        let likeTapped: ControlEvent<Void>?
    }
    
    struct Output{
        let filterDetailData: Driver<FilterResponseDTO>
        let filterValueItems: Driver<[FilterValuesEntity]>
        let creatorHashTags: Driver<[String]>
        let likeState: Driver<Bool>
        let likeCount: Driver<Int>
        let networkError: Signal<NetworkError>
    }
    
    func transform(input: Input) -> Output {
        let filterDetailDataRelay = PublishRelay<FilterResponseDTO>()
        let networkErrorRelay = PublishRelay<NetworkError>()
        let filterValueItemsRelay = PublishRelay<[FilterValuesEntity]>()
        let creatorHashTagsRelay = PublishRelay<[String]>()
        let likeStateRelay = PublishRelay<Bool>() //좋아요(찜) 상태
        let likeCountRelay = PublishRelay<Int>() //좋아요(찜 개수
        
        filterIdRelay
            .subscribe(onNext: { filterId in
                Task{
                    do{
                        let dto: FilterResponseDTO = try await NetworkManager.shared.request(FilterRouter.detailFilter(filterId: filterId))
                        filterDetailDataRelay.accept(dto)
                        filterValueItemsRelay.accept(dto.filterValues.toEntity())
                        creatorHashTagsRelay.accept(dto.creator.hashTags)
                        LikeStore.shared.setLiked(id: dto.filterId, liked: dto.isLiked, count: dto.likeCount)
                        likeStateRelay.accept(dto.isLiked)
                    }catch(let error as NetworkError){
                        networkErrorRelay.accept(error)
                    }catch(let error){
                        networkErrorRelay.accept(NetworkError.unknown(error))
                    }
                }
            })
            .disposed(by: disposeBag)

        externalFilterValuesRelay
            .map { $0.toEntity() }
            .bind(to: filterValueItemsRelay)
            .disposed(by: disposeBag)

        var requestId = 0
        var latestRequestId = 0

        input.likeTapped?
            .compactMap{ $0 }
            .withLatestFrom(filterDetailDataRelay)
            .map { detail -> (detail: FilterResponseDTO, desiredLiked: Bool, requestId: Int, prevLiked: Bool, prevCount: Int) in
                let prevLiked = LikeStore.shared.isLiked(id: detail.filterId) //원본 좋아요(찜) 상태
                let prevCount = LikeStore.shared.likeCount(id: detail.filterId) ?? detail.likeCount //원본 좋아요(찜) 개수
                let desiredLiked = !prevLiked //원하는 좋아요 상태
                let optimisticCount = max(0, prevCount + (desiredLiked ? 1 : -1))
                LikeStore.shared.setLiked(id: detail.filterId, liked: desiredLiked, count: optimisticCount)

                likeStateRelay.accept(desiredLiked)
                requestId += 1
                latestRequestId = requestId
                return (detail, desiredLiked, requestId, prevLiked, prevCount)
            }
            // 연속 탭 시 UI는 즉시 반영하고, 서버 통신은 마지막 한 번만 수행
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .flatMapLatest { payload -> Observable<Bool> in
                let detail = payload.detail
                let id = detail.filterId
                let desiredLiked = payload.desiredLiked
                let requestId = payload.requestId
                let prevLiked = payload.prevLiked
                let prevCount = payload.prevCount

                return Observable<Bool>.create { observer in
                    Task {
                        do {
                            let dto: PostLikeResponseDTO = try await NetworkManager.shared.request(
                                FilterRouter.like(filterId: id, liked: desiredLiked)
                            )
                            observer.onNext(dto.likeStatus)
                            observer.onCompleted()
                        } catch {
                            observer.onError(error)
                        }
                    }
                    return Disposables.create()
                }
                .flatMap { likedNow -> Observable<Bool> in
                    guard latestRequestId == requestId else { return .empty() }
                    let baseCount = LikeStore.shared.likeCount(id: id) ?? detail.likeCount
                    let finalCount: Int
                    if likedNow == desiredLiked {
                        finalCount = baseCount
                    } else {
                        finalCount = max(0, baseCount + (likedNow ? 1 : -1))
                    }
                    LikeStore.shared.setLiked(id: id, liked: likedNow, count: finalCount)
                    return .just(likedNow)
                }
                .catch { error in
                    networkErrorRelay.accept(error as? NetworkError ?? .unknown(error))
                    guard latestRequestId == requestId else { return .empty() }
                    LikeStore.shared.setLiked(id: id, liked: prevLiked, count: prevCount)
                    return .just(prevLiked)
                }
            }
            .bind(to: likeStateRelay)
            .disposed(by: disposeBag)
        
        Observable
            .combineLatest(LikeStore.shared.likeCounts, filterIdRelay.asObservable())
            .compactMap { counts, id in counts[id] }
            .bind(to: likeCountRelay)
            .disposed(by: disposeBag)
        
        return Output(
            filterDetailData: filterDetailDataRelay.asDriver(onErrorDriveWith: .empty()),
            filterValueItems: filterValueItemsRelay.asDriver(onErrorDriveWith: .empty()),
            creatorHashTags: creatorHashTagsRelay.asDriver(onErrorDriveWith: .empty()),
            likeState: likeStateRelay.asDriver(onErrorDriveWith: .empty()),
            likeCount: likeCountRelay.asDriver(onErrorDriveWith: .empty()),
            networkError: networkErrorRelay.asSignal()
        )
    }
}
