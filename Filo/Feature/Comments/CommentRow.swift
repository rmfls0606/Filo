//
//  CommentRow.swift
//  Filo
//
//  Created by 이상민 on 2/7/26.
//

import Foundation

struct CommentRow {
    let commentId: String
    let content: String
    let createdAt: String
    let creator: UserInfoResponseDTO
    let isReply: Bool
    let parentCommentId: String?
}

extension CommentRow {
    init(dto: PostCommentResponseDTO) {
        self.commentId = dto.commentId
        self.content = dto.content
        self.createdAt = dto.createdAt
        self.creator = dto.creator
        self.isReply = false
        self.parentCommentId = nil
    }
    
    init(dto: RepliesCommentResponseDTO, parentCommentId: String) {
        self.commentId = dto.commentId
        self.content = dto.content
        self.createdAt = dto.createdAt
        self.creator = dto.creator
        self.isReply = true
        self.parentCommentId = parentCommentId
    }
    
    init(dto: CommentResponseDTO, parentCommentId: String?) {
        self.commentId = dto.commentId
        self.content = dto.content
        self.createdAt = dto.createdAt
        self.creator = dto.creator
        self.isReply = parentCommentId != nil
        self.parentCommentId = parentCommentId
    }
}
