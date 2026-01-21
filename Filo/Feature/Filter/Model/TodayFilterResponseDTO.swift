//
//  TodayFilterResponseDTO.swift
//  Filo
//
//  Created by 이상민 on 1/21/26.
//

import Foundation

struct TodayFilterResponseDTO: Decodable, Sendable{
    let filterId: String
    let title: String
    let introduction: String
    let description: String
    let files: [String]
    let createdAt: String
    let updatedAt: String
    
    private enum CodingKeys: String, CodingKey {
        case filterId = "filter_id"
        case title
        case introduction
        case description
        case files
        case createdAt
        case updatedAt
    }
}

extension TodayFilterResponseDTO{
    func toEntity() -> TodayFilterResponseEntity{
        return TodayFilterResponseEntity(
            filterId: filterId,
            title: title,
            introduction: introduction,
            description: description,
            files: files,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
