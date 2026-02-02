//
//  PostSummaryPaginationResponseDTO.swift
//  Filo
//
//  Created by 이상민 on 2/3/26.
//

import Foundation

struct PostSummaryPaginationResponseDTO: Decodable, Sendable{
    let data: [PostSummaryResponseDTO]
    let nextCursor: String
    
    private enum CodingKeys: String, CodingKey {
        case data
        case nextCursor = "next_cursor"
    }
}

struct PostSummaryResponseDTO: Decodable, Sendable{
    let postId: String
    let category: String
    let title: String
    let content: String
    let geolocation: Geolocation
    let creator: UserInfoResponseDTO
    let files: [String]
    let isLike: Bool
    let likeCount: Int
    let createdAt: String
    let updatedAt: String
    
    private enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case category
        case title
        case content
        case geolocation
        case creator
        case files
        case isLike = "is_like"
        case likeCount = "like_count"
        case createdAt
        case updatedAt
    }
}

struct Geolocation: Decodable, Sendable{
    let longitude: Double
    let latitude: Double
}
