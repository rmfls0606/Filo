//
//  SearchViewModel.swift
//  Filo
//
//  Created by 이상민 on 2/7/26.
//

import Foundation
import RxSwift
import RxCocoa

struct SearchCategoryItem {
    let type: searchCategoryType
    let isSelected: Bool
}

enum SearchResultItem {
    case keyword(String)
    case user(UserInfoResponseDTO)
}

enum searchCategoryType: String, CaseIterable{
    case all = "전체"
    case food = "푸드"
    case people = "인물"
    case landscape = "풍경"
    case night = "야경"
    case star = "별"
    
    var query: String{
        switch self {
        case .all: ""
        case .food: "푸드"
        case .people: "인물"
        case .landscape: "풍경"
        case .night: "야경"
        case .star: "별"
        }
    }
}

final class SearchViewModel: ViewModelType {
    enum SearchOrder: String, CaseIterable {
        case createdAt = "최신순"
        case like = "인기순"
        
        var orderBy: String {
            switch self {
            case .createdAt: return "createdAt"
            case .like: return "likes"
            }
        }
        
        var next: SearchOrder {
            switch self {
            case .createdAt: return .like
            case .like: return .createdAt
            }
        }
    }
    
    struct Input {
        let searchText: Observable<String>
        let searchSubmit: Observable<Void>
        let categorySelected: ControlEvent<SearchCategoryItem>
        let orderTapped: ControlEvent<Void>
        let refresh: Observable<Void>
        let postSelected: ControlEvent<PostSummaryResponseDTO>
        let loadNextPage: Observable<Void>
        let cancelLoadNextPage: Observable<Void>
    }
    
    struct Output {
        let categories: Driver<[SearchCategoryItem]>
        let posts: Driver<[PostSummaryResponseDTO]>
        let results: Driver<[SearchResultItem]>
        let orderTitle: Driver<String>
        let isInitialLoading: Driver<Bool>
        let isAppendLoading: Driver<Bool>
        let selectedPost: Driver<String>
        let networkError: Signal<NetworkError>
    }
    
    private let service: NetworkManagerProtocol
    private let disposeBag = DisposeBag()
    
    init(service: NetworkManagerProtocol = NetworkManager.shared) {
        self.service = service
    }
    
    func transform(input: Input) -> Output {
        let categoriesRelay = BehaviorRelay<[SearchCategoryItem]>(value: searchCategoryType.allCases.map { type in
            SearchCategoryItem(type: type, isSelected: type == .all)
        })
        let selectedCategoryRelay = BehaviorRelay<searchCategoryType>(value: .all)
        let orderRelay = BehaviorRelay<SearchOrder>(value: .createdAt)
        let searchTextRelay = BehaviorRelay<String>(value: "")
        let postsRelay = BehaviorRelay<[PostSummaryResponseDTO]>(value: [])
        let nextCursorRelay = BehaviorRelay<String>(value: "")
        let isLoadingRelay = BehaviorRelay<Bool>(value: false)
        let isAppendLoadingRelay = BehaviorRelay<Bool>(value: false)
        let isLastPageRelay = BehaviorRelay<Bool>(value: false)
        let selectedPostRelay = PublishRelay<String>()
        let resultsRelay = BehaviorRelay<[SearchResultItem]>(value: [])
        let errorRelay = PublishRelay<NetworkError>()
        var currentQueryId = 0
        var pagingRequestToken = 0
        var inFlightPageTask: Task<Void, Never>?
        
        let textTrigger = input.searchText
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .debounce(.milliseconds(400), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .share(replay: 1)
        
        textTrigger
            .bind(to: searchTextRelay)
            .disposed(by: disposeBag)
        
        input.categorySelected
            .map{ $0.type }
            .bind(to: selectedCategoryRelay)
            .disposed(by: disposeBag)
        
        selectedCategoryRelay
            .subscribe{ item in
                let updated = categoriesRelay.value.map {
                    SearchCategoryItem(type: $0.type, isSelected: $0.type == item)
                }
                categoriesRelay.accept(updated)
            }
            .disposed(by: disposeBag)
        
        input.orderTapped
            .subscribe(onNext: {
                orderRelay.accept(orderRelay.value.next)
            })
            .disposed(by: disposeBag)
        
        
        let resetTrigger = Observable.merge(
            Observable.just(()),
            input.categorySelected.map { _ in },
            input.orderTapped.map { _ in },
            input.refresh)
            .share(replay: 1)
        
        let requestPage: (_ next: String, _ append: Bool, _ queryId: Int, _ category: searchCategoryType, _ order: SearchOrder) -> Void = {
            next, append, queryId, category, order in
            inFlightPageTask?.cancel()
            isLoadingRelay.accept(true)
            isAppendLoadingRelay.accept(append)
            pagingRequestToken += 1
            let requestToken = pagingRequestToken
            
            inFlightPageTask = Task {
                do {
                    let dto: PostSummaryPaginationResponseDTO = try await self.service.request(
                        CommunityRouter.geolocation(category: category.query,
                                                    longitude: "",
                                                    latitude: "",
                                                    maxDistance: "",
                                                    limit: "30",
                                                    next: next,
                                                    orderBy: order.orderBy)
                    )
                    guard !Task.isCancelled else { return }
                    guard currentQueryId == queryId, pagingRequestToken == requestToken else { return }
                    let merged = append ? (postsRelay.value + dto.data) : dto.data
                    postsRelay.accept(merged)
                    nextCursorRelay.accept(dto.nextCursor)
                    isLastPageRelay.accept(dto.nextCursor == "0")
                    isLoadingRelay.accept(false)
                    isAppendLoadingRelay.accept(false)
                } catch let error as NetworkError {
                    guard !Task.isCancelled else { return }
                    guard currentQueryId == queryId, pagingRequestToken == requestToken else { return }
                    isLoadingRelay.accept(false)
                    isAppendLoadingRelay.accept(false)
                    errorRelay.accept(error)
                } catch {
                    guard !Task.isCancelled else { return }
                    guard currentQueryId == queryId, pagingRequestToken == requestToken else { return }
                    isLoadingRelay.accept(false)
                    isAppendLoadingRelay.accept(false)
                    errorRelay.accept(.unknown(error))
                }
            }
        }
        
        resetTrigger
            .withLatestFrom(Observable.combineLatest(selectedCategoryRelay, orderRelay))
            .subscribe(onNext: { [weak self] category, order in
                guard let self else { return }
                currentQueryId += 1
                let queryId = currentQueryId
                inFlightPageTask?.cancel()
                postsRelay.accept([])
                nextCursorRelay.accept("")
                isLastPageRelay.accept(false)
                isLoadingRelay.accept(false)
                isAppendLoadingRelay.accept(false)
                requestPage("", false, queryId, category, order)
            })
            .disposed(by: disposeBag)
        
        input.loadNextPage
            .withLatestFrom(Observable.combineLatest(
                nextCursorRelay.asObservable(),
                isLoadingRelay.asObservable(),
                isLastPageRelay.asObservable(),
                selectedCategoryRelay.asObservable(),
                orderRelay.asObservable()
            ))
            .filter { nextCursor, isLoading, isLastPage, _, _ in
                !isLoading && !isLastPage && !nextCursor.isEmpty && nextCursor != "0"
            }
            .subscribe(onNext: { nextCursor, _, _, category, order in
                requestPage(nextCursor, true, currentQueryId, category, order)
            })
            .disposed(by: disposeBag)
        
        input.cancelLoadNextPage
            .withLatestFrom(Observable.combineLatest(isLoadingRelay.asObservable(), isAppendLoadingRelay.asObservable()))
            .filter { isLoading, isAppendLoading in
                isLoading && isAppendLoading
            }
            .subscribe(onNext: { _, _ in
                pagingRequestToken += 1
                inFlightPageTask?.cancel()
                isLoadingRelay.accept(false)
                isAppendLoadingRelay.accept(false)
            })
            .disposed(by: disposeBag)

        textTrigger
            .withLatestFrom(searchTextRelay)
            .subscribe(onNext: { [weak self] query in
                guard let self else { return }
                guard !query.isEmpty else {
                    resultsRelay.accept([])
                    return
                }
                
                Task {
                    do {
                        let dto: UserInfoListResponseDTO = try await self.service.request(
                            UserRouter.search(nick: query)
                        )
                        let items: [SearchResultItem] = [.keyword(query)] + dto.data.map { .user($0) }
                        resultsRelay.accept(items)
                    } catch let error as NetworkError {
                        errorRelay.accept(error)
                    } catch {
                        errorRelay.accept(.unknown(error))
                    }
                }
            })
            .disposed(by: disposeBag)
        
        input.postSelected
            .map{ $0.postId }
            .bind { postId in
                selectedPostRelay.accept(postId)
            }
            .disposed(by: disposeBag)
        
        let isInitialLoading = Observable
            .combineLatest(postsRelay.asObservable(), isLoadingRelay.asObservable())
            .map { posts, isLoading in
                isLoading && posts.isEmpty
            }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: false)
        
        let isAppendLoading = Observable
            .combineLatest(postsRelay.asObservable(), isLoadingRelay.asObservable(), isAppendLoadingRelay.asObservable())
            .map { posts, isLoading, isAppendLoading in
                isLoading && isAppendLoading && !posts.isEmpty
            }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: false)
        
        return Output(
            categories: categoriesRelay.asDriver(),
            posts: postsRelay.asDriver(),
            results: resultsRelay.asDriver(),
            orderTitle: orderRelay.map { $0.rawValue }.asDriver(onErrorJustReturn: SearchOrder.createdAt.rawValue),
            isInitialLoading: isInitialLoading,
            isAppendLoading: isAppendLoading,
            selectedPost: selectedPostRelay.asDriver(onErrorDriveWith: .empty()),
            networkError: errorRelay.asSignal()
        )
    }
}
