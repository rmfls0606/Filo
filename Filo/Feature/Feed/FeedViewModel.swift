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
    private struct QueryParams: Equatable {
        let category: String
        let order: OrderByItem
    }
    
    let category: String
    private let disposeBag = DisposeBag()
    
    init(category: String = ""){
        self.category = category
    }
    
    struct Input{
        let orderByItemSelected: Observable<OrderByItem>
        let feedCellTapped: Observable<FilterSummaryResponseEntity>
        let feedFilterModeSelected: ControlEvent<Void>
        let likeTapped: Observable<LikeInputTap>
        let loadNextPage: Observable<Void>
    }
    
    struct Output{
        let selectedOrder: Driver<OrderByItem>
        let filtersData: Driver<FilterSummaryPaginationListResponseEntity>
        let feedFilterMode: Driver<Bool>
        let isInitialLoading: Driver<Bool>
        let likeUIUpdate: Driver<OutputLikeUpdate>
        let selectedFilterId: Driver<String>
        let networkError: Signal<NetworkError>
    }
    
    private typealias PagingState = (
        entity: FilterSummaryPaginationListResponseEntity,
        isLastPage: Bool,
        isLoading: Bool,
        category: String,
        order: OrderByItem
    )
    
    func transform(input: Input) -> Output {
        let selectedOrderRelay = BehaviorRelay<OrderByItem>(value: .popularity)
        let filtersDataRelay = BehaviorRelay<FilterSummaryPaginationListResponseEntity>(
            value: FilterSummaryPaginationListResponseEntity(data: [], nextCursor: "")
        )
        let networkErrorRelay = PublishRelay<NetworkError>()
        let categoryRelay = BehaviorRelay<String>(value: category)
        let feedFileterModeRelay = BehaviorRelay<Bool>(value: true) //true: listMode, false: blockMode
        let likeUIUpdateRelay = PublishRelay<OutputLikeUpdate>()
        let selectedFilterIdRelay = PublishRelay<String>()
        let isLoadingRelay = BehaviorRelay<Bool>(value: false)
        let isLastPageRelay = BehaviorRelay<Bool>(value: false)
        var currentQueryId = 0
        
        input.orderByItemSelected
            .bind(to: selectedOrderRelay)
            .disposed(by: disposeBag)
        
        let requestPage: (_ next: String, _ append: Bool, _ queryId: Int, _ category: String, _ order: OrderByItem) -> Void = {
            next, append, queryId, category, order in
            isLoadingRelay.accept(true)
            
            Task {
                do {
                    let dto: FilterSummaryPaginationListResponseDTO = try await NetworkManager.shared.request(
                        FilterRouter.filters(
                            next: next,
                            limit: "30",
                            category: category,
                            orderBy: order.orderByName
                        )
                    )
                    let entity = dto.toEntity()
                    entity.data.forEach { item in
                        LikeStore.shared.setLiked(id: item.filterId, liked: item.isLiked, count: item.likeCount)
                    }
                    
                    guard currentQueryId == queryId else { return }
                    let mergedData = append ? (filtersDataRelay.value.data + entity.data) : entity.data
                    filtersDataRelay.accept(
                        FilterSummaryPaginationListResponseEntity(
                            data: mergedData,
                            nextCursor: entity.nextCursor
                        )
                    )
                    isLastPageRelay.accept(entity.nextCursor == "0")
                    isLoadingRelay.accept(false)
                } catch let error as NetworkError {
                    guard currentQueryId == queryId else { return }
                    isLoadingRelay.accept(false)
                    networkErrorRelay.accept(error)
                } catch {
                    guard currentQueryId == queryId else { return }
                    isLoadingRelay.accept(false)
                    networkErrorRelay.accept(NetworkError.unknown(error))
                }
            }
        }
        
        let queryParams: Observable<QueryParams> = Observable
            .combineLatest(categoryRelay.asObservable(), selectedOrderRelay.asObservable())
            .map { category, order in
                QueryParams(category: category, order: order)
            }
            .distinctUntilChanged()
        
        queryParams
            .subscribe(onNext: { params in
                currentQueryId += 1
                let queryId = currentQueryId
                isLastPageRelay.accept(false)
                filtersDataRelay.accept(FilterSummaryPaginationListResponseEntity(data: [], nextCursor: ""))
                requestPage("", false, queryId, params.category, params.order)
            })
            .disposed(by: disposeBag)
        
        let pagingState: Observable<PagingState> = Observable.combineLatest(
            filtersDataRelay.asObservable(),
            isLastPageRelay.asObservable(),
            isLoadingRelay.asObservable(),
            categoryRelay.asObservable(),
            selectedOrderRelay.asObservable()
        ) { entity, isLastPage, isLoading, category, order in
            (entity, isLastPage, isLoading, category, order)
        }
        
        input.loadNextPage
            .withLatestFrom(pagingState)
            .filter { (_, isLastPage, isLoading, _, _) in
                !isLastPage && !isLoading
            }
            .subscribe(onNext: { entity, _, _, category, order in
                let next = entity.nextCursor
                guard !next.isEmpty, next != "0" else { return }
                requestPage(next, true, currentQueryId, category, order)
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

        input.feedCellTapped
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .map { $0.filterId }
            .bind(to: selectedFilterIdRelay)
            .disposed(by: disposeBag)
        
        input.feedFilterModeSelected
            .withLatestFrom(feedFileterModeRelay)
            .map{ !$0 }
            .bind(to: feedFileterModeRelay)
            .disposed(by: disposeBag)
        
        let isInitialLoading = Observable
            .combineLatest(filtersDataRelay.asObservable(), isLoadingRelay.asObservable())
            .map { entity, isLoading in
                isLoading && entity.data.isEmpty
            }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: false)
        
        return Output(
            selectedOrder: selectedOrderRelay.asDriver(),
            filtersData: filtersDataRelay.asDriver(),
            feedFilterMode: feedFileterModeRelay.asDriver(),
            isInitialLoading: isInitialLoading,
            likeUIUpdate: likeUIUpdateRelay.asDriver(onErrorDriveWith: .empty()),
            selectedFilterId: selectedFilterIdRelay.asDriver(onErrorDriveWith: .empty()),
            networkError: networkErrorRelay.asSignal()
        )
    }
}
