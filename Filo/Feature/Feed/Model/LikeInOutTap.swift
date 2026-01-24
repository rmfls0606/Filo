//
//  LikeInOutTap.swift
//  Filo
//
//  Created by 이상민 on 1/25/26.
//

import Foundation

struct LikeInputTap {
    let index: Int
    let item: FilterSummaryResponseEntity
}

struct OutputLikeUpdate {
    let filterId: String
    let index: Int
    let liked: Bool
    let likeCount: Int
}
