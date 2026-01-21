//
//  FilterRouter.swift
//  Filo
//
//  Created by 이상민 on 1/20/26.
//

import Alamofire

enum FilterRouter: APITarget{
    case todayFilter
    
    var path: String{
        switch self {
        case .todayFilter:
            return "/filters/today-filter"
        }
    }
    
    var method: HTTPMethod{
        switch self {
        case .todayFilter:
            return .get
        }
    }
    
    var headers: HTTPHeaders{
        return ["Authorization": NetworkConfig.authorization,
                "SeSACKey": NetworkConfig.apiKey]
    }
    
    var parameters: Parameters?{
        switch self {
        case .todayFilter:
            return nil
        }
    }
    
    var encoding: ParameterEncoding{
        switch self {
        case .todayFilter:
            return URLEncoding.default
        }
    }
}
