//
//  FilterSummaryResponseEntity.swift
//  Filo
//
//  Created by 이상민 on 1/22/26.
//

import Foundation

struct FilterSummaryResponseEntity{
    let filterId: String
    let category: String?
    let title: String
    let description: String
    let files: [String]
    let creator: UserInfoResponseDTO
    var isLiked: Bool
    var likeCount: Int
    let buyerCount: Int
    let createdAt: String
    let updatedAt: String
}
