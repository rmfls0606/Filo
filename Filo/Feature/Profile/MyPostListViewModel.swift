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
        let likePostTap: Observable<PostSummaryResponseDTO>
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
                        dto.data.forEach { item in
                            LikeStore.shared.setLiked(id: item.postId, liked: item.isLike, count: item.likeCount)
                        }
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
        
        var requestIdById: [String: Int] = [:]
        var latestRequestIdById: [String: Int] = [:]
        
        input.likePostTap
            .groupBy { $0.postId }
            .flatMap { [weak self] group -> Observable<Void> in
                guard let self else { return .empty() }
                return group
                    .map { item -> (id: String, desiredLiked: Bool, requestId: Int, prevLiked: Bool, prevCount: Int, optimisticCount: Int, originalCount: Int) in
                        let prevLiked = LikeStore.shared.isLiked(id: item.postId)
                        let prevCount = LikeStore.shared.likeCount(id: item.postId) ?? item.likeCount
                        let desiredLiked = !prevLiked
                        let optimisticCount = max(0, prevCount + (desiredLiked ? 1 : -1))
                        LikeStore.shared.setLiked(id: item.postId, liked: desiredLiked, count: optimisticCount)
                        
                        let requestId = (requestIdById[item.postId] ?? 0) + 1
                        requestIdById[item.postId] = requestId
                        latestRequestIdById[item.postId] = requestId
                        
                        return (item.postId, desiredLiked, requestId, prevLiked, prevCount, optimisticCount, item.likeCount)
                    }
                    .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
                    .flatMapLatest { payload -> Observable<Void> in
                        let id = payload.id
                        let requestId = payload.requestId
                        let desiredLiked = payload.desiredLiked
                        let prevLiked = payload.prevLiked
                        let prevCount = payload.prevCount
                        let originalCount = payload.originalCount
                        
                        return Observable<Bool>.create { observer in
                            Task {
                                do {
                                    let dto: PostLikeResponseDTO = try await self.service.request(
                                        CommunityRouter.like(postId: id, isLike: desiredLiked)
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
                            let baseCount = LikeStore.shared.likeCount(id: id) ?? originalCount
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
            posts: postsRelay.asDriver(onErrorDriveWith: .empty()),
            selectedPostId: selectedRelay.asDriver(onErrorDriveWith: .empty()),
            networkError: errorRelay.asSignal()
        )
    }
}
