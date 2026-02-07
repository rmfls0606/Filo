//
//  CommentsViewModel.swift
//  Filo
//
//  Created by 이상민 on 2/7/26.
//

import Foundation
import RxSwift
import RxCocoa

final class CommentsViewModel: ViewModelType {
    struct Input {
        let viewWillAppear: Observable<Void>
        let sendTapped: Observable<Void>
        let commentText: Observable<String>
        let replyTarget: Observable<CommentReplyTarget?>
        let expandReplies: Observable<String>
    }
    
    struct Output {
        let comments: Driver<[CommentListItem]>
        let sendEnabled: Driver<Bool>
        let sendSuccess: Signal<Void>
        let networkError: Signal<NetworkError>
    }
    
    private let disposeBag = DisposeBag()
    private let postId: String
    private let service: NetworkManagerProtocol
    private let initialComments: [PostCommentResponseDTO]
    
    init(postId: String,
         initialComments: [PostCommentResponseDTO],
         service: NetworkManagerProtocol = NetworkManager.shared) {
        self.postId = postId
        self.initialComments = initialComments
        self.service = service
    }
    
    func transform(input: Input) -> Output {
        let commentsRelay = BehaviorRelay<[CommentListItem]>(value: flatten(initialComments, expanded: []))
        let commentsDataRelay = BehaviorRelay<[PostCommentResponseDTO]>(value: initialComments)
        let errorRelay = PublishRelay<NetworkError>()
        let successRelay = PublishRelay<Void>()
        let replyTargetRelay = BehaviorRelay<CommentReplyTarget?>(value: nil)
        let expandedRelay = BehaviorRelay<Set<String>>(value: [])
        
        input.viewWillAppear
            .map { [initialComments] in initialComments }
            .bind(to: commentsDataRelay)
            .disposed(by: disposeBag)
        
        input.replyTarget
            .bind(to: replyTargetRelay)
            .disposed(by: disposeBag)
        
        input.expandReplies
            .withLatestFrom(expandedRelay) { id, set in
                var newSet = set
                newSet.insert(id)
                return newSet
            }
            .bind(to: expandedRelay)
            .disposed(by: disposeBag)
        
        Observable.combineLatest(commentsDataRelay, expandedRelay)
            .map { [weak self] comments, expanded in
                self?.flatten(comments, expanded: expanded) ?? []
            }
            .bind(to: commentsRelay)
            .disposed(by: disposeBag)
        
        let sendEnabled = input.commentText
            .map { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .distinctUntilChanged()
        
        input.sendTapped
            .withLatestFrom(Observable.combineLatest(input.commentText, replyTargetRelay))
            .map { (text: $0.0.trimmingCharacters(in: .whitespacesAndNewlines), replyTarget: $0.1) }
            .filter { !$0.text.isEmpty }
            .subscribe(onNext: { [weak self] payload in
                guard let self else { return }
                Task {
                    do {
                        let dto: CommentResponseDTO = try await self.service.request(
                            CommentRouter.postComments(postId: self.postId,
                                                       parent_comment_id: payload.replyTarget?.commentId ?? "",
                                                       content: payload.text)
                        )
                        var store = commentsDataRelay.value
                        if let parentId = payload.replyTarget?.commentId {
                            if let index = store.firstIndex(where: { $0.commentId == parentId }) {
                                let reply = RepliesCommentResponseDTO(
                                    commentId: dto.commentId,
                                    content: dto.content,
                                    createdAt: dto.createdAt,
                                    creator: dto.creator
                                )
                                let parent = store[index]
                                let updatedReplies = parent.replies + [reply]
                                let updated = PostCommentResponseDTO(
                                    commentId: parent.commentId,
                                    content: parent.content,
                                    createdAt: parent.createdAt,
                                    creator: parent.creator,
                                    replies: updatedReplies
                                )
                                store[index] = updated
                            }
                        } else {
                            let newComment = PostCommentResponseDTO(
                                commentId: dto.commentId,
                                content: dto.content,
                                createdAt: dto.createdAt,
                                creator: dto.creator,
                                replies: []
                            )
                            store.append(newComment)
                        }
                        commentsDataRelay.accept(store)
                        if let parentId = payload.replyTarget?.commentId {
                            expandedRelay.accept(expandedRelay.value.union([parentId]))
                        }
                        replyTargetRelay.accept(nil)
                        successRelay.accept(())
                    } catch let error as NetworkError {
                        errorRelay.accept(error)
                    } catch {
                        errorRelay.accept(.unknown(error))
                    }
                }
            })
            .disposed(by: disposeBag)
        
        return Output(
            comments: commentsRelay.asDriver(),
            sendEnabled: sendEnabled.asDriver(onErrorJustReturn: false),
            sendSuccess: successRelay.asSignal(),
            networkError: errorRelay.asSignal()
        )
    }
    
    private func flatten(_ comments: [PostCommentResponseDTO], expanded: Set<String>) -> [CommentListItem] {
        var result: [CommentListItem] = []
        for comment in comments {
            result.append(.comment(CommentRow(dto: comment)))
            let replies = comment.replies
            let isExpanded = expanded.contains(comment.commentId)
            let visibleReplies = isExpanded ? replies : Array(replies.prefix(2))
            for reply in visibleReplies {
                result.append(.comment(CommentRow(dto: reply, parentCommentId: comment.commentId)))
            }
            if !isExpanded && replies.count > 2 {
                result.append(.moreReplies(parentCommentId: comment.commentId, remaining: replies.count - 2))
            }
        }
        return result
    }
}
