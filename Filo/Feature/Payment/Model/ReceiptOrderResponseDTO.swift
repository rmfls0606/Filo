//
//  ReceiptOrderResponseDTO.swift
//  Filo
//
//  Created by 이상민 on 2/5/26.
//

import Foundation

struct ReceiptOrderResponseDTO: Decodable, Sendable{
    let paymentId: String
    let orderItem: OrderResponseDTO?
    let createdAt: String
    let updatedAt: String
    
    private enum CodingKeys: String, CodingKey {
        case paymentId = "payment_id"
        case orderItem = "order_item"
        case createdAt
        case updatedAt
    }
}

struct OrderResponseDTO: Decodable, Sendable{
    let orderId: String
    let orderCode: String
    let filter: FilterSummaryResponseDTO_Order?
    let paidAt: String
    let createdAt: String
    let updatedAt: String
    
    private enum CodingKeys: String, CodingKey {
        case orderId = "order_id"
        case orderCode = "order_code"
        case filter
        case paidAt
        case createdAt
        case updatedAt
    }
}

struct FilterSummaryResponseDTO_Order: Decodable, Sendable{
    let id: String?
    let category: String
    let title: String
    let description: String
    let files: [String]
    let price: Int
    let creator: UserInfoResponseDTO?
    let filterValues: FilterValuesDTO?
    let createdAt: String
    let updatedAt: String
    
    private enum CodingKeys: String, CodingKey {
        case id
        case category
        case title
        case description
        case files
        case price
        case creator
        case filterValues = "filter_values"
        case createdAt
        case updatedAt
    }
}
