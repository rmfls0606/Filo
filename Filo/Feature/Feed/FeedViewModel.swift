//
//  FeedViewModel.swift
//  Filo
//
//  Created by 이상민 on 1/23/26.
//

import Foundation
import RxSwift
import RxCocoa

final class FeedViewModel: ViewModelType {
    let category: String
    private let disposeBag = DisposeBag()
    
    init(category: String = ""){
        self.category = category
    }
    
    struct Input{
        let orderByItemSelected: Observable<OrderByItem>
        let feedFilterModeSelected: ControlEvent<Void>
        let likeTapped: Observable<LikeInputTap>
    }
    
    struct Output{
        let selectedOrder: Driver<OrderByItem>
        let filtersData: Driver<FilterSummaryPaginationListResponseEntity>
        let feedFilterMode: Driver<Bool>
        let likeUIUpdate: Driver<OutputLikeUpdate>
    }
    
    func transform(input: Input) -> Output {
        let selectedOrderRelay = BehaviorRelay<OrderByItem>(value: .popularity)
        let filtersDataRelay = PublishRelay<FilterSummaryPaginationListResponseEntity>()
        let networkErrorRelay = PublishRelay<NetworkError>()
        let categoryRelay = BehaviorRelay<String>(value: category)
        let feedFileterModeRelay = BehaviorRelay<Bool>(value: true) //true: listMode, false: blockMode
        let likeUIUpdateRelay = PublishRelay<OutputLikeUpdate>()
        
        input.orderByItemSelected
            .bind(to: selectedOrderRelay)
            .disposed(by: disposeBag)
        
        Observable
            .combineLatest(categoryRelay, selectedOrderRelay){ category, selected in
                return (category: category, selected: selected)
            }
            .distinctUntilChanged{ $0.selected == $1.selected}
            .subscribe(onNext: { parm in
                Task{
                    do{
                        let dto: FilterSummaryPaginationListResponseDTO = try await NetworkManager.shared.request(FilterRouter.filters(next: "", limit: "", category: parm.category, orderBy: parm.selected.orderByName))
                        let entity = dto.toEntity()
                        entity.data.forEach { item in
                            LikeStore.shared.setLiked(id: item.filterId, liked: item.isLiked, count: item.likeCount)
                        }
                        filtersDataRelay.accept(entity)
                    }catch(let error as NetworkError){
                        print(error)
                        networkErrorRelay.accept(error)
                    }
                }
            })
            .disposed(by: disposeBag)
        
        var requestIdById: [String: Int] = [:]
        var latestRequestIdById: [String: Int] = [:]

        input.likeTapped
            .groupBy { $0.item.filterId }
            .flatMap { group -> Observable<OutputLikeUpdate> in
                group
                    // Optimistic(낙관적 업데이트)
                    .map { tap -> (tap: LikeInputTap, desiredLiked: Bool, requestId: Int, prevLiked: Bool, prevCount: Int, optimisticCount: Int) in
                        let id = tap.item.filterId
                        let currentLiked = LikeStore.shared.isLiked(id: id)
                        let desiredLiked = !currentLiked
                        let prevCount = LikeStore.shared.likeCount(id: id) ?? tap.item.likeCount
                        let optimisticCount = max(0, prevCount + (desiredLiked ? 1 : -1))
                        LikeStore.shared.setLiked(id: id, liked: desiredLiked, count: optimisticCount)

                        let requestId = (requestIdById[id] ?? 0) + 1
                        requestIdById[id] = requestId
                        latestRequestIdById[id] = requestId
                        return (tap, desiredLiked, requestId, currentLiked, prevCount, optimisticCount)
                    }
                    .do(onNext: { payload in
                        likeUIUpdateRelay.accept(OutputLikeUpdate(
                            filterId: payload.tap.item.filterId,
                            liked: payload.desiredLiked,
                            likeCount: payload.optimisticCount
                        ))
                    })//연타 후 마지막만 서버 요청
                    .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
                    .flatMapLatest { payload -> Observable<OutputLikeUpdate> in
                        let tap = payload.tap
                        let id = tap.item.filterId
                        let requestId = payload.requestId
                        let desiredLiked = payload.desiredLiked
                        let prevLiked = payload.prevLiked
                        let prevCount = payload.prevCount

                        return Observable.create { observer in
                            Task{
                                do{
                                    let dto: PostLikeResponseDTO = try await NetworkManager.shared.request(
                                        FilterRouter.like(filterId: id, liked: desiredLiked)
                                    )
                                    observer.onNext(dto.toEntity())
                                    observer.onCompleted()
                                }catch{
                                    observer.onError(error)
                                }
                            }
                            return Disposables.create()
                        }
                        .flatMap { entity -> Observable<OutputLikeUpdate> in
                            guard latestRequestIdById[id] == requestId else { return .empty() }
                            let likedNow = entity.likeStatus
                            let baseCount = LikeStore.shared.likeCount(id: id) ?? tap.item.likeCount
                            let finalCount: Int
                            if likedNow == desiredLiked {
                                finalCount = baseCount
                            } else {
                                finalCount = max(0, baseCount + (likedNow ? 1 : -1))
                            }
                            LikeStore.shared.setLiked(id: id, liked: likedNow, count: finalCount)
                            return .just(OutputLikeUpdate(
                                filterId: id,
                                liked: likedNow,
                                likeCount: finalCount
                            ))
                        }
                        .catch { error in
                            networkErrorRelay.accept(error as? NetworkError ?? .unknown(error))
                            guard latestRequestIdById[id] == requestId else { return .empty() }
                            LikeStore.shared.setLiked(id: id, liked: prevLiked, count: prevCount)
                            return .just(OutputLikeUpdate(
                                filterId: id,
                                liked: prevLiked,
                                likeCount: prevCount
                            ))
                        }
                    }
            }
            .bind(to: likeUIUpdateRelay)
            .disposed(by: disposeBag)
        
        input.feedFilterModeSelected
            .withLatestFrom(feedFileterModeRelay)
            .map{ !$0 }
            .bind(to: feedFileterModeRelay)
            .disposed(by: disposeBag)
        
        return Output(
            selectedOrder: selectedOrderRelay.asDriver(),
            filtersData: filtersDataRelay.asDriver(onErrorDriveWith: .empty()),
            feedFilterMode: feedFileterModeRelay.asDriver(),
            likeUIUpdate: likeUIUpdateRelay.asDriver(onErrorDriveWith: .empty())
        )
    }
}
