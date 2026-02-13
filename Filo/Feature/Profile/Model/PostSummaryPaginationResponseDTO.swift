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
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let decoded = try? container.decode([PostSummaryResponseDTO].self, forKey: .data) {
            data = decoded
        } else {
            let fallback = try container.decode([FailableDecodable<PostSummaryResponseDTO>].self, forKey: .data)
            data = fallback.compactMap { $0.value }
        }
        nextCursor = try container.decodeIfPresent(String.self, forKey: .nextCursor) ?? ""
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
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        postId = try container.decode(String.self, forKey: .postId)
        category = (try? container.decode(String.self, forKey: .category)) ?? ""
        title = (try? container.decode(String.self, forKey: .title)) ?? ""
        content = (try? container.decode(String.self, forKey: .content)) ?? ""
        geolocation = (try? container.decode(Geolocation.self, forKey: .geolocation))
            ?? Geolocation(longitude: 0, latitude: 0)
        creator = (try? container.decode(UserInfoResponseDTO.self, forKey: .creator))
            ?? UserInfoResponseDTO(userID: "", nick: "", name: nil, introduction: nil, profileImage: nil, hashTags: [])
        files = (try? container.decode([String].self, forKey: .files)) ?? []
        isLike = (try? container.decode(Bool.self, forKey: .isLike)) ?? false
        likeCount = (try? container.decode(Int.self, forKey: .likeCount)) ?? 0
        createdAt = (try? container.decode(String.self, forKey: .createdAt)) ?? ""
        updatedAt = (try? container.decode(String.self, forKey: .updatedAt)) ?? ""
    }
}

struct Geolocation: Decodable, Sendable{
    let longitude: Double
    let latitude: Double
}

private struct FailableDecodable<T: Decodable>: Decodable {
    let value: T?
    
    init(from decoder: any Decoder) throws {
        value = try? T(from: decoder)
    }
}
