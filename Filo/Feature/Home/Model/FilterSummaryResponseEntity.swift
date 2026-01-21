//
//  FilterSummaryResponseEntity.swift
//  Filo
//
//  Created by 이상민 on 1/22/26.
//

import Foundation

struct FilterSummaryResponseEntity{
    let filterId: String
    let title: String
    let likeCount: Int
    let files: [String]
}
