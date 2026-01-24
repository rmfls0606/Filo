//
//  PostLikeResponseDTO.swift
//  Filo
//
//  Created by 이상민 on 1/24/26.
//

import Foundation

struct PostLikeResponseDTO: Decodable, Sendable{
    let likeStatus: Bool
    
    private enum CodingKeys: String, CodingKey {
        case likeStatus = "like_status"
    }
}

extension PostLikeResponseDTO{
    func toEntity() -> PostLikeResponseEntity{
        return PostLikeResponseEntity(
            likeStatus: likeStatus
        )
    }
}
