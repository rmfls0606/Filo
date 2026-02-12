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
        let editTarget: Observable<String?>
        let deleteComment: Observable<String>
    }
    
    struct Output {
        let comments: Driver<[CommentListItem]>
        let rawComments: Driver<[PostCommentResponseDTO]>
        let sendEnabled: Driver<Bool>
        let sendSuccess: Signal<Void>
        let totalCount: Driver<Int>
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

    var currentPostId: String {
        postId
    }
    
    func transform(input: Input) -> Output {
        let commentsRelay = BehaviorRelay<[CommentListItem]>(value: flatten(initialComments, expanded: []))
        let commentsDataRelay = BehaviorRelay<[PostCommentResponseDTO]>(value: initialComments)
        let errorRelay = PublishRelay<NetworkError>()
        let successRelay = PublishRelay<Void>()
        let replyTargetRelay = BehaviorRelay<CommentReplyTarget?>(value: nil)
        let expandedRelay = BehaviorRelay<Set<String>>(value: [])
        let editTargetRelay = BehaviorRelay<String?>(value: nil)
        
        input.viewWillAppear
            .map { [initialComments] in initialComments }
            .bind(to: commentsDataRelay)
            .disposed(by: disposeBag)
        
        input.replyTarget
            .bind(to: replyTargetRelay)
            .disposed(by: disposeBag)
        
        input.editTarget
            .bind(to: editTargetRelay)
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
            .withLatestFrom(Observable.combineLatest(input.commentText, replyTargetRelay, editTargetRelay))
            .map { (text: $0.0.trimmingCharacters(in: .whitespacesAndNewlines), replyTarget: $0.1, editTarget: $0.2) }
            .filter { !$0.text.isEmpty }
            .subscribe(onNext: { [weak self] payload in
                guard let self else { return }
                Task {
                    do {
                        if let editId = payload.editTarget {
                            let _: CommentResponseDTO = try await self.service.request(
                                CommentRouter.putComments(postId: self.postId, commentId: editId, content: payload.text)
                            )
                            var store = commentsDataRelay.value
                            if let index = store.firstIndex(where: { $0.commentId == editId }) {
                                let origin = store[index]
                                let updated = PostCommentResponseDTO(
                                    commentId: origin.commentId,
                                    content: payload.text,
                                    createdAt: origin.createdAt,
                                    creator: origin.creator,
                                    replies: origin.replies
                                )
                                store[index] = updated
                            } else {
                                for i in store.indices {
                                    let parent = store[i]
                                    if let replyIndex = parent.replies.firstIndex(where: { $0.commentId == editId }) {
                                        var replies = parent.replies
                                        let reply = replies[replyIndex]
                                        let updated = RepliesCommentResponseDTO(
                                            commentId: reply.commentId,
                                            content: payload.text,
                                            createdAt: reply.createdAt,
                                            creator: reply.creator
                                        )
                                        replies[replyIndex] = updated
                                        let updatedParent = PostCommentResponseDTO(
                                            commentId: parent.commentId,
                                            content: parent.content,
                                            createdAt: parent.createdAt,
                                            creator: parent.creator,
                                            replies: replies
                                        )
                                        store[i] = updatedParent
                                        break
                                    }
                                }
                            }
                            commentsDataRelay.accept(store)
                            editTargetRelay.accept(nil)
                        } else {
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
                        }
                        successRelay.accept(())
                    } catch let error as NetworkError {
                        errorRelay.accept(error)
                    } catch {
                        errorRelay.accept(.unknown(error))
                    }
                }
            })
            .disposed(by: disposeBag)

        input.deleteComment
            .subscribe(onNext: { [weak self] commentId in
                guard let self else { return }
                Task {
                    do {
                        try await self.service.requestEmpty(
                            CommentRouter.deleteComments(postId: self.postId, commentId: commentId)
                        )
                        var store = commentsDataRelay.value
                        if let index = store.firstIndex(where: { $0.commentId == commentId }) {
                            store.remove(at: index)
                        } else {
                            for i in store.indices {
                                let parent = store[i]
                                if parent.replies.contains(where: { $0.commentId == commentId }) {
                                    let filtered = parent.replies.filter { $0.commentId != commentId }
                                    let updatedParent = PostCommentResponseDTO(
                                        commentId: parent.commentId,
                                        content: parent.content,
                                        createdAt: parent.createdAt,
                                        creator: parent.creator,
                                        replies: filtered
                                    )
                                    store[i] = updatedParent
                                    break
                                }
                            }
                        }
                        commentsDataRelay.accept(store)
                    } catch let error as NetworkError {
                        errorRelay.accept(error)
                    } catch {
                        errorRelay.accept(.unknown(error))
                    }
                }
            })
            .disposed(by: disposeBag)
        
        let totalCount = commentsDataRelay
            .map { comments in
                let replyCount = comments.reduce(0) { $0 + $1.replies.count }
                return comments.count + replyCount
            }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: 0)
        
        return Output(
            comments: commentsRelay.asDriver(),
            rawComments: commentsDataRelay.asDriver(),
            sendEnabled: sendEnabled.asDriver(onErrorJustReturn: false),
            sendSuccess: successRelay.asSignal(),
            totalCount: totalCount,
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
