//
//  MyFilterListViewModel.swift
//  Filo
//
//  Created by 이상민 on 2/8/26.
//

import Foundation
import RxSwift
import RxCocoa

final class MyFilterListViewModel: ViewModelType {
    struct Input {
        let viewWillAppear: Observable<Void>
        let selectedItem: Observable<FilterSummaryResponseEntity>
        let likeFilterTap: Observable<String>
    }
    
    struct Output {
        let filters: Driver<[FilterSummaryResponseEntity]>
        let selectedFilterId: Driver<String>
        let networkError: Signal<NetworkError>
    }
    
    private let service: NetworkManagerProtocol
    private let disposeBag = DisposeBag()
    
    init(service: NetworkManagerProtocol = NetworkManager.shared) {
        self.service = service
    }
    
    func transform(input: Input) -> Output {
        let filtersRelay = BehaviorRelay<[FilterSummaryResponseEntity]>(value: [])
        let selectedRelay = PublishRelay<String>()
        let errorRelay = PublishRelay<NetworkError>()
        
        input.viewWillAppear
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                Task {
                    do {
                        let currentUserId = (try? KeychainManager.shared.read(key: .userId)) ?? ""
                        guard !currentUserId.isEmpty else { return }
                        let dto: FilterSummaryPaginationListResponseDTO = try await self.service.request(
                            FilterRouter.user(userId: currentUserId, next: "", limit: "30", category: "")
                        )
                        let entity = dto.toEntity()
                        entity.data.forEach { item in
                            LikeStore.shared.setLiked(id: item.filterId, liked: item.isLiked, count: item.likeCount)
                        }
                        filtersRelay.accept(entity.data)
                    } catch let error as NetworkError {
                        errorRelay.accept(error)
                    } catch {
                        errorRelay.accept(.unknown(error))
                    }
                }
            })
            .disposed(by: disposeBag)
        
        input.selectedItem
            .map { $0.filterId }
            .bind(to: selectedRelay)
            .disposed(by: disposeBag)
        
        var requestIdById: [String: Int] = [:]
        var latestRequestIdById: [String: Int] = [:]
        
        input.likeFilterTap
            .groupBy { $0 }
            .flatMap { [weak self] group -> Observable<Void> in
                guard let self else { return .empty() }
                return group
                    .map { filterId -> (id: String, desiredLiked: Bool, requestId: Int, prevLiked: Bool, prevCount: Int, optimisticCount: Int) in
                        let prevLiked = LikeStore.shared.isLiked(id: filterId)
                        let prevCount = LikeStore.shared.likeCount(id: filterId) ?? 0
                        let desiredLiked = !prevLiked
                        let optimisticCount = max(0, prevCount + (desiredLiked ? 1 : -1))
                        LikeStore.shared.setLiked(id: filterId, liked: desiredLiked, count: optimisticCount)
                        
                        let requestId = (requestIdById[filterId] ?? 0) + 1
                        requestIdById[filterId] = requestId
                        latestRequestIdById[filterId] = requestId
                        
                        return (filterId, desiredLiked, requestId, prevLiked, prevCount, optimisticCount)
                    }
                    .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
                    .flatMapLatest { payload -> Observable<Void> in
                        let id = payload.id
                        let requestId = payload.requestId
                        let desiredLiked = payload.desiredLiked
                        let prevLiked = payload.prevLiked
                        let prevCount = payload.prevCount
                        
                        return Observable<Bool>.create { observer in
                            Task {
                                do {
                                    let dto: FilterLikeResponseDTO = try await self.service.request(
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
                        .flatMap { likedNow -> Observable<Void> in
                            guard latestRequestIdById[id] == requestId else { return .empty() }
                            let baseCount = LikeStore.shared.likeCount(id: id) ?? prevCount
                            let finalCount: Int
                            if likedNow == desiredLiked {
                                finalCount = baseCount
                            } else {
                                finalCount = max(0, baseCount + (likedNow ? 1 : -1))
                            }
                            LikeStore.shared.setLiked(id: id, liked: likedNow, count: finalCount)
                            return .just(())
                        }
                        .catch { error in
                            guard latestRequestIdById[id] == requestId else { return .empty() }
                            LikeStore.shared.setLiked(id: id, liked: prevLiked, count: prevCount)
                            errorRelay.accept(error as? NetworkError ?? .unknown(error))
                            return .just(())
                        }
                    }
            }
            .subscribe()
            .disposed(by: disposeBag)
        
        return Output(
            filters: filtersRelay.asDriver(onErrorDriveWith: .empty()),
            selectedFilterId: selectedRelay.asDriver(onErrorDriveWith: .empty()),
            networkError: errorRelay.asSignal()
        )
    }
}
