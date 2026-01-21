//
//  FilterCategory.swift
//  Filo
//
//  Created by 이상민 on 12/18/25.
//

import Foundation

enum FilterCategorySection: String{
    case main = "카테고리"
}

enum FilterCategoryType: String, CaseIterable, Hashable{
    case food = "푸드"
    case people = "인물"
    case landscape = "풍경"
    case night = "야경"
    case star = "별"
    
    var imageName: String{
        return String(describing: self)
    }
}

nonisolated
struct FilterCategoryEntity: Hashable{
    let type: FilterCategoryType
    var isSelected: Bool = false
}
