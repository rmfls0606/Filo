//
//  FilterSummaryPaginationListResponseDTO.swift
//  Filo
//
//  Created by 이상민 on 1/20/26.
//

import Foundation

struct FilterSummaryPaginationListResponseDTO: Decodable, Sendable{
    let data: [FilterSummaryResponseDTO]
    let nextCursor: String
    
    private enum CodingKeys: String, CodingKey {
        case data
        case nextCursor = "next_cursor"
    }
}

struct FilterSummaryResponseDTO: Decodable, Sendable{
    let filterId: String
    let category: String?
    let title: String
    let description: String
    let files: [String]
    let creator: UserInfoResponseDTO
    let isLiked: Bool
    let likeCount: Int
    let buyerCount: Int
    let createdAt: String
    let updatedAt: String
    
    private enum CodingKeys: String, CodingKey {
        case filterId = "filter_id"
        case category
        case title
        case description
        case files
        case creator
        case isLiked = "is_liked"
        case likeCount = "like_count"
        case buyerCount = "buyer_count"
        case createdAt
        case updatedAt
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.filterId = try container.decode(String.self, forKey: .filterId)
        self.category = try container.decodeIfPresent(String.self, forKey: .category) ?? ""
        self.title = try container.decode(String.self, forKey: .title)
        self.description = try container.decode(String.self, forKey: .description)
        self.files = try container.decode([String].self, forKey: .files)
        self.creator = try container.decode(UserInfoResponseDTO.self, forKey: .creator)
        self.isLiked = try container.decode(Bool.self, forKey: .isLiked)
        self.likeCount = try container.decode(Int.self, forKey: .likeCount)
        self.buyerCount = try container.decode(Int.self, forKey: .buyerCount)
        self.createdAt = try container.decode(String.self, forKey: .createdAt)
        self.updatedAt = try container.decode(String.self, forKey: .updatedAt)
    }
}

extension FilterSummaryPaginationListResponseDTO{
    func toEntity() -> FilterSummaryPaginationListResponseEntity{
        return FilterSummaryPaginationListResponseEntity(
            data: data,
            nextCursor: nextCursor
        )
    }
}

extension FilterSummaryResponseDTO{
    func toEntity() -> FilterSummaryResponseEntity{
        return FilterSummaryResponseEntity(
            filterId: filterId,
            title: title,
            likeCount: likeCount,
            files: files
        )
    }
}

// TODO: User폴더로 빼야함
struct UserInfoResponseDTO: Decodable, Sendable{
    let userID: String
    let nick: String
    let name: String?
    let introduction: String?
    let profileImage: String?
    let hashTags: [String]
    
    private enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case nick
        case name
        case introduction
        case profileImage
        case hashTags
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.userID = try container.decode(String.self, forKey: .userID)
        self.nick = try container.decode(String.self, forKey: .nick)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.introduction = try container.decodeIfPresent(String.self, forKey: .introduction)
        self.profileImage = try container.decodeIfPresent(String.self, forKey: .profileImage)
        self.hashTags = try container.decode([String].self, forKey: .hashTags)
    }
}
