//
//  OrderRouter.swift
//  Filo
//
//  Created by 이상민 on 2/4/26.
//

import Alamofire

enum OrderRouter: APITarget{
    case order(filterId: String, totalPrice: Int)
    
    var path: String{
        switch self {
        case .order:
            return "/orders"
        }
    }
    
    var method: HTTPMethod{
        switch self {
        case .order:
            return .post
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
        }
    }
    
    var encoding: ParameterEncoding{
        switch self {
        case .order:
            return JSONEncoding.default
        }
    }
}

