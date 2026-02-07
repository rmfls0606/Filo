//
//  CommentResponseDTO.swift
//  Filo
//
//  Created by 이상민 on 2/7/26.
//

import Foundation

struct CommentResponseDTO: Decodable, Sendable{
    let commentId: String
    let content: String
    let createdAt: String
    let creator: UserInfoResponseDTO
    
    private enum CodingKeys: String, CodingKey {
        case commentId = "comment_id"
        case content
        case createdAt
        case creator
    }
}
