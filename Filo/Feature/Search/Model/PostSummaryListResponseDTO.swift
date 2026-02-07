//
//  PostSummaryListResponseDTO.swift
//  Filo
//
//  Created by 이상민 on 2/7/26.
//

import Foundation

struct PostSummaryListResponseDTO: Decodable, Sendable{
    let data: [PostSummaryResponseDTO]
    let nextCursor: String?

    private enum CodingKeys: String, CodingKey {
        case data
        case nextCursor = "next_cursor"
    }
}
