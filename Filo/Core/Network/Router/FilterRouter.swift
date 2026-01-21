//
//  FilterRouter.swift
//  Filo
//
//  Created by 이상민 on 1/20/26.
//

import Alamofire

enum FilterRouter: APITarget{
    case todayFilter
    case hotTrend
    
    var path: String{
        switch self {
        case .todayFilter:
            return "/filters/today-filter"
        case .hotTrend:
            return "/filters/hot-trend"
        }
    }
    
    var method: HTTPMethod{
        switch self {
        case .hotTrend, .todayFilter:
            return .get
        }
    }
    
    var headers: HTTPHeaders{
        return ["Authorization": NetworkConfig.authorization,
                "SeSACKey": NetworkConfig.apiKey]
    }
    
    var parameters: Parameters?{
        switch self {
        case .todayFilter, .hotTrend:
            return nil
        }
    }
    
    var encoding: ParameterEncoding{
        switch self {
        case .todayFilter, .hotTrend:
            return URLEncoding.default
        }
    }
}
