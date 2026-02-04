//
//  OrderCreateResponseDTO.swift
//  Filo
//
//  Created by 이상민 on 2/4/26.
//

import Foundation

struct OrderCreateResponseDTO: Decodable, Sendable{
    let orderId: String
    let orderCode: String
    let totalPrice: Int
    let createdAt: String
    let updatedAt: String
    
    private enum CodingKeys: String, CodingKey {
        case orderId = "order_id"
        case orderCode = "order_code"
        case totalPrice = "total_price"
        case createdAt
        case updatedAt
    }
}
