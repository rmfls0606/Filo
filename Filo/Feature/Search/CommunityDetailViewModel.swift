//
//  CommunityDetailViewModel.swift
//  Filo
//
//  Created by 이상민 on 2/7/26.
//

import Foundation
import RxSwift
import RxCocoa

final class CommunityDetailViewModel: ViewModelType {
    enum MenuAction {
        case edit
        case delete
    }

    struct Input {
        let likeTapped: ControlEvent<Void>
        let menuAction: Observable<MenuAction>
        let refresh: Observable<Void>
    }
    
    struct Output {
        let postDetail: Driver<PostResponseDTO>
        let isOwner: Driver<Bool>
        let menuAction: Signal<MenuAction>
        let deleteSuccess: Signal<Void>
        let likeState: Driver<Bool>
        let likeCount: Driver<Int>
        let networkError: Signal<NetworkError>
    }
    
    private let disposeBag = DisposeBag()
    private let postIdRelay: BehaviorRelay<String>
    private let service: NetworkManagerProtocol
    
    
    init(postId: String, service: NetworkManagerProtocol = NetworkManager.shared) {
        self.postIdRelay = BehaviorRelay(value: postId)
        self.service = service
    }
    
    func transform(input: Input) -> Output {
        let detailRelay = BehaviorRelay<PostResponseDTO?>(value: nil)
        let isOwnerRelay = PublishRelay<Bool>()
        let menuActionRelay = PublishRelay<MenuAction>()
        let deleteSuccessRelay = PublishRelay<Void>()
        let likeStateRelay = PublishRelay<Bool>()
        let likeCountRelay = PublishRelay<Int>()
        let errorRelay = PublishRelay<NetworkError>()
        let currentUserIdRelay = BehaviorRelay<String>(value: "")
        
        Task {
            let currentUserId = await TokenStorage.shared.userId() ?? ""
            currentUserIdRelay.accept(currentUserId)
        }

        let detailTrigger = Observable.merge(
            postIdRelay.asObservable().map { _ in },
            input.refresh
        )

        detailTrigger
            .withLatestFrom(postIdRelay.asObservable())
            .subscribe(onNext: { [weak self] postId in
                guard let self else { return }
                Task {
                    do {
                        let dto: PostResponseDTO = try await self.service.request(
                            CommunityRouter.detail(postId: postId)
                        )
                        detailRelay.accept(dto)
                        LikeStore.shared.setLiked(id: dto.postId, liked: dto.isLike, count: dto.likeCount)
                        likeStateRelay.accept(dto.isLike)
                    } catch let error as NetworkError {
                        errorRelay.accept(error)
                    } catch {
                        errorRelay.accept(.unknown(error))
                    }
                }
            })
            .disposed(by: disposeBag)

        let detailStream = detailRelay
            .compactMap { $0 }
            .share(replay: 1)

        Observable
            .combineLatest(detailStream, currentUserIdRelay)
            .map { detail, userId in detail.creator.userID == userId }
            .bind(to: isOwnerRelay)
            .disposed(by: disposeBag)

        input.menuAction
            .bind(to: menuActionRelay)
            .disposed(by: disposeBag)

        input.menuAction
            .withLatestFrom(detailStream) { ($0, $1) }
            .filter { action, _ in action == .delete }
            .subscribe(onNext: { [weak self] _, detail in
                guard let self else { return }
                Task {
                    do {
                        try await self.service.requestEmpty(CommunityRouter.delete(postId: detail.postId))
                        deleteSuccessRelay.accept(())
                    } catch let error as NetworkError {
                        errorRelay.accept(error)
                    } catch {
                        errorRelay.accept(.unknown(error))
                    }
                }
            })
            .disposed(by: disposeBag)
        
        var requestId = 0
        var latestRequestId = 0
        
        input.likeTapped
            .withLatestFrom(detailStream)
            .map { detail -> (detail: PostResponseDTO, desiredLiked: Bool, requestId: Int, prevLiked: Bool, prevCount: Int) in
                let prevLiked = LikeStore.shared.isLiked(id: detail.postId)
                let prevCount = LikeStore.shared.likeCount(id: detail.postId) ?? detail.likeCount
                let desiredLiked = !prevLiked
                let optimisticCount = max(0, prevCount + (desiredLiked ? 1 : -1))
                LikeStore.shared.setLiked(id: detail.postId, liked: desiredLiked, count: optimisticCount)
                likeStateRelay.accept(desiredLiked)
                requestId += 1
                latestRequestId = requestId
                return (detail, desiredLiked, requestId, prevLiked, prevCount)
            }
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .flatMapLatest { payload -> Observable<Bool> in
                let detail = payload.detail
                let desiredLiked = payload.desiredLiked
                let requestId = payload.requestId
                let prevLiked = payload.prevLiked
                let prevCount = payload.prevCount
                
                return Observable<Bool>.create { observer in
                    Task {
                        do {
                            let dto: PostLikeResponseDTO = try await NetworkManager.shared.request(
                                CommunityRouter.like(postId: detail.postId, isLike: desiredLiked)
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
                    let baseCount = LikeStore.shared.likeCount(id: detail.postId) ?? detail.likeCount
                    let finalCount: Int
                    if likedNow == desiredLiked {
                        finalCount = baseCount
                    } else {
                        finalCount = max(0, baseCount + (likedNow ? 1 : -1))
                    }
                    LikeStore.shared.setLiked(id: detail.postId, liked: likedNow, count: finalCount)
                    return .just(likedNow)
                }
                .catch { error in
                    errorRelay.accept(error as? NetworkError ?? .unknown(error))
                    guard latestRequestId == requestId else { return .empty() }
                    LikeStore.shared.setLiked(id: detail.postId, liked: prevLiked, count: prevCount)
                    return .just(prevLiked)
                }
            }
            .bind(to: likeStateRelay)
            .disposed(by: disposeBag)
        
        Observable
            .combineLatest(LikeStore.shared.likeCounts, postIdRelay.asObservable())
            .compactMap { counts, id in counts[id] }
            .bind(to: likeCountRelay)
            .disposed(by: disposeBag)
        
        return Output(
            postDetail: detailRelay.compactMap { $0 }.asDriver(onErrorDriveWith: .empty()),
            isOwner: isOwnerRelay.asDriver(onErrorJustReturn: false),
            menuAction: menuActionRelay.asSignal(),
            deleteSuccess: deleteSuccessRelay.asSignal(),
            likeState: likeStateRelay.asDriver(onErrorDriveWith: .empty()),
            likeCount: likeCountRelay.asDriver(onErrorDriveWith: .empty()),
            networkError: errorRelay.asSignal()
        )
    }
}
