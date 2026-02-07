//
//  PostResponseDTO.swift
//  Filo
//
//  Created by 이상민 on 2/7/26.
//

import Foundation

struct PostResponseDTO: Decodable, Sendable{
    let postId: String
    let category: String
    let title: String
    let content: String
    let gelocation: Geolocation
    let creator: UserInfoResponseDTO
    let files: [String]
    let isLike: Bool
    let likeCount: Int
    let comments: [PostCommentResponseDTO]
    let createdAt: String
    let updatedAt: String
    
    private enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case category
        case title
        case content
        case gelocation
        case creator
        case files
        case isLike = "is_like"
        case likeCount = "like_count"
        case comments
        case createdAt
        case updatedAt
    }
}

struct PostCommentResponseDTO: Decodable, Sendable{
    let commentId: String
    let content: String
    let createdAt: String
    let creator: UserInfoResponseDTO
    let replies: [RepliesCommentResponseDTO]
    
    private enum CodingKeys: String, CodingKey {
        case commentId = "comment_id"
        case content
        case createdAt
        case creator
        case replies
    }
}

struct RepliesCommentResponseDTO: Decodable, Sendable{
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
