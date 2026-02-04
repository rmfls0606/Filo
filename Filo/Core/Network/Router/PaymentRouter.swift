//
//  PaymentRouter.swift
//  Filo
//
//  Created by 이상민 on 2/5/26.
//

import Alamofire

enum PaymentRouter: APITarget{
    case validation(impUId: String)
    
    var path: String{
        switch self {
        case .validation:
            return "/payments/validation"
        }
    }
    
    var method: HTTPMethod{
        switch self {
        case .validation:
            return .post
        }
    }
    
    var headers: HTTPHeaders{
        return ["Authorization": NetworkConfig.authorization,
                "SeSACKey": NetworkConfig.apiKey]
    }
    
    var parameters: Parameters?{
        switch self {
        case .validation(let impUId):
            print(impUId)
            return ["imp_uid": impUId]
        }
    }
    
    var encoding: ParameterEncoding{
        switch self {
        case .validation:
            return JSONEncoding.default
        }
    }
}

