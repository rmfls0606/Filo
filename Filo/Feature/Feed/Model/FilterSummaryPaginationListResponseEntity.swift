//
//  FilterSummaryPaginationListResponseEntity.swift
//  Filo
//
//  Created by 이상민 on 1/23/26.
//

import Foundation

struct FilterSummaryPaginationListResponseEntity{
    let data: [FilterSummaryResponseDTO]
    let nextCursor: String
}
