//
//  OrderRouter.swift
//  Filo
//
//  Created by 이상민 on 2/4/26.
//

import Alamofire

enum OrderRouter: APITarget{
    case order(filterId: String, totalPrice: Int)
    case fetchOrders
    
    var path: String{
        switch self {
        case .order, .fetchOrders:
            return "/orders"
        }
    }
    
    var method: HTTPMethod{
        switch self {
        case .order:
            return .post
        case .fetchOrders:
            return .get
        }
    }
    
    var headers: HTTPHeaders{
        return ["Authorization": NetworkConfig.authorization,
                "SeSACKey": NetworkConfig.apiKey]
    }
    
    var parameters: Parameters?{
        switch self {
        case .order(let filterId, let totalPrice):
            return ["filter_id": filterId,
                    "total_price": totalPrice]
        case .fetchOrders:
            return nil
        }
    }
    
    var encoding: ParameterEncoding{
        switch self {
        case .order:
            return JSONEncoding.default
        case .fetchOrders:
            return URLEncoding.default
        }
    }
}
