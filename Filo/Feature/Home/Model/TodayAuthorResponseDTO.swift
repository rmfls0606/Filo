//
//  TodayAuthorResponseDTO.swift
//  Filo
//
//  Created by 이상민 on 1/22/26.
//

import Foundation

struct TodayAuthorResponseDTO: Decodable, Sendable{
    let author: TodayAuthorInfoResponseDTO
    let filters: [FilterSummaryResponseDTO]
}

struct TodayAuthorInfoResponseDTO: Decodable, Sendable{
    let userId: String
    let nick: String
    let name: String
    let introduction: String
    let description: String
    let profileImage: String
    let hashTags: [String]
    
    private enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case nick
        case name
        case introduction
        case description
        case profileImage
        case hashTags
    }
}

extension TodayAuthorResponseDTO{
    func toEntity() -> TodayAuthorResponseEntity{
        return TodayAuthorResponseEntity(
            author: author,
            filters: filters
        )
    }
}
