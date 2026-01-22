//
//  BannerRouter.swift
//  Filo
//
//  Created by 이상민 on 1/22/26.
//

import Alamofire

enum BannerRouter: APITarget{
    case main
    
    var path: String{
        switch self {
        case .main:
            return "/banners/main"
        }
    }
    
    var method: HTTPMethod{
        switch self {
        case .main:
            return .get
        }
    }
    
    var headers: HTTPHeaders{
        return ["Authorization": NetworkConfig.authorization,
                "SeSACKey": NetworkConfig.apiKey]
    }
    
    var parameters: Parameters?{
        switch self {
        case .main:
            return nil
        }
    }
    
    var encoding: ParameterEncoding{
        switch self {
        case .main:
            return URLEncoding.default
        }
    }
}

