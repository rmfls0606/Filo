//
//  CommentListItem.swift
//  Filo
//
//  Created by 이상민 on 2/7/26.
//

import Foundation

enum CommentListItem {
    case comment(CommentRow)
    case moreReplies(parentCommentId: String, remaining: Int)
}
