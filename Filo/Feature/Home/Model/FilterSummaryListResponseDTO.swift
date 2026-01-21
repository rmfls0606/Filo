//
//  FilterSummaryListResponseDTO.swift
//  Filo
//
//  Created by 이상민 on 1/22/26.
//

import Foundation

struct FilterSummaryListResponseDTO: Decodable, Sendable{
    let data: [FilterSummaryResponseDTO]
}
