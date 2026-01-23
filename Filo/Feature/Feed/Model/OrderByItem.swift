//
//  OrderByItem.swift
//  Filo
//
//  Created by 이상민 on 1/24/26.
//

import Foundation

enum OrderByItem: String, CaseIterable{
    case popularity = "인기순"
    case purchase = "구매순"
    case latest = "최신순"
    
    var orderByName: String{
        return String(describing: self)
    }
}
