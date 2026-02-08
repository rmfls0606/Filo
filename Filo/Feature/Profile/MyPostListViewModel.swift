//
//  MyPostListViewModel.swift
//  Filo
//
//  Created by 이상민 on 2/8/26.
//

import Foundation
import RxSwift
import RxCocoa

final class MyPostListViewModel: ViewModelType {
    struct Input {
        let viewWillAppear: Observable<Void>
        let refresh: Observable<Void>
        let selectedItem: Observable<PostSummaryResponseDTO>
    }
    
    struct Output {
        let posts: Driver<[PostSummaryResponseDTO]>
        let selectedPostId: Driver<String>
        let networkError: Signal<NetworkError>
    }
    
    private let service: NetworkManagerProtocol
    private let disposeBag = DisposeBag()
    
    init(service: NetworkManagerProtocol = NetworkManager.shared) {
        self.service = service
    }
    
    func transform(input: Input) -> Output {
        let postsRelay = BehaviorRelay<[PostSummaryResponseDTO]>(value: [])
        let selectedRelay = PublishRelay<String>()
        let errorRelay = PublishRelay<NetworkError>()
        
        Observable.merge(input.viewWillAppear, input.refresh)
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                Task {
                    do {
                        let currentUserId = (try? KeychainManager.shared.read(key: .userId)) ?? ""
                        guard !currentUserId.isEmpty else { return }
                        let dto: PostSummaryPaginationResponseDTO = try await self.service.request(
                            CommunityRouter.user(category: "", limit: "30", next: "", userId: currentUserId)
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
        
        input.selectedItem
            .map { $0.postId }
            .bind(to: selectedRelay)
            .disposed(by: disposeBag)
        
        return Output(
            posts: postsRelay.asDriver(onErrorDriveWith: .empty()),
            selectedPostId: selectedRelay.asDriver(onErrorDriveWith: .empty()),
            networkError: errorRelay.asSignal()
        )
    }
}
