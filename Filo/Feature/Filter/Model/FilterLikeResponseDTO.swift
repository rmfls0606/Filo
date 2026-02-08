//
//  FilterLikeResponseDTO.swift
//  Filo
//
//  Created by 이상민 on 2/8/26.
//

import Foundation

struct FilterLikeResponseDTO: Decodable, Sendable {
    let likeStatus: Bool
    
    private enum CodingKeys: String, CodingKey {
        case likeStatus = "like_status"
    }
}
