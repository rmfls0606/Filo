//
//  SearchResultViewModel.swift
//  Filo
//
//  Created by 이상민 on 2/7/26.
//

import Foundation
import RxSwift
import RxCocoa

final class SearchResultViewModel: ViewModelType {
    struct Input {
        let searchText: ControlProperty<String>
        let searchSubmit: ControlEvent<Void>
        let selectedPost: ControlEvent<PostSummaryResponseDTO>
    }
    
    struct Output {
        let posts: Driver<[PostSummaryResponseDTO]>
        let networkError: Signal<NetworkError>
        let selectedPost: Driver<String>
    }
    
    private let query: String
    private let service: NetworkManagerProtocol
    private let disposeBag = DisposeBag()
    
    init(query: String, service: NetworkManagerProtocol = NetworkManager.shared) {
        self.query = query
        self.service = service
    }
    
    func transform(input: Input) -> Output {
        let queryRelay = BehaviorRelay<String>(value: query)
        let postsRelay = BehaviorRelay<[PostSummaryResponseDTO]>(value: [])
        let errorRelay = PublishRelay<NetworkError>()
        let selectedPostRelay = PublishRelay<String>()
        
        let submitQuery = input.searchSubmit
            .withLatestFrom(input.searchText)
            .share(replay: 1)
        
        let trigger = Observable.merge(queryRelay.asObservable(), submitQuery)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .distinctUntilChanged()
        
        trigger
            .subscribe(onNext: { [weak self] query in
                guard let self else { return }
                Task {
                    do {
                        let dto: PostSummaryListResponseDTO = try await self.service.request(
                            CommunityRouter.search(title: query)
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
        
        input.selectedPost
            .map{ $0.postId }
            .bind(to: selectedPostRelay)
            .disposed(by: disposeBag)
        
        return Output(
            posts: postsRelay.asDriver(),
            networkError: errorRelay.asSignal(),
            selectedPost: selectedPostRelay.asDriver(onErrorDriveWith: .empty())
        )
    }
}

