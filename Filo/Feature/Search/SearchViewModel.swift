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
    }
    
    struct Output {
        let categories: Driver<[SearchCategoryItem]>
        let posts: Driver<[PostSummaryResponseDTO]>
        let results: Driver<[SearchResultItem]>
        let orderTitle: Driver<String>
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
        let selectedPostRelay = PublishRelay<String>()
        let resultsRelay = BehaviorRelay<[SearchResultItem]>(value: [])
        let errorRelay = PublishRelay<NetworkError>()
        
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
        
        
        let postTrigger = Observable.merge(
            Observable.just(()),
            input.categorySelected.map { _ in },
            input.orderTapped.map { _ in },
            input.refresh)
            .share(replay: 1)
        
        postTrigger
            .withLatestFrom(Observable.combineLatest(selectedCategoryRelay, orderRelay))
            .subscribe(onNext: { [weak self] category, order in
                guard let self else { return }
                Task {
                    do {
                        let dto: PostSummaryPaginationResponseDTO = try await self.service.request(
                            CommunityRouter.geolocation(category: category.query,
                                                        longitude: "",
                                                        latitude: "",
                                                        maxDistance: "",
                                                        limit: "30",
                                                        next: "",
                                                        orderBy: order.orderBy)
                        )
                        
                        postsRelay.accept(dto.data)
                    } catch let error as NetworkError {
                        errorRelay.accept(error)
                    } catch {
                        errorRelay.accept(.unknown(error))
                    }
                }
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
        
        return Output(
            categories: categoriesRelay.asDriver(),
            posts: postsRelay.asDriver(),
            results: resultsRelay.asDriver(),
            orderTitle: orderRelay.map { $0.rawValue }.asDriver(onErrorJustReturn: SearchOrder.createdAt.rawValue),
            selectedPost: selectedPostRelay.asDriver(onErrorDriveWith: .empty()),
            networkError: errorRelay.asSignal()
        )
    }
}
