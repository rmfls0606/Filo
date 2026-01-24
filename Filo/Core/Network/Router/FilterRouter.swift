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
    case filters(next: String, limit: String, category: String, orderBy: String)
    case like(filterId: String, liked: Bool)

    var path: String{
        switch self {
        case .todayFilter:
            return "/filters/today-filter"
        case .hotTrend:
            return "/filters/hot-trend"
        case .filters:
            return "/filters"
        case .like(let filterId, _):
            return "/filters/\(filterId)/like"
        }
    }
    
    var method: HTTPMethod{
        switch self {
        case .hotTrend, .todayFilter, .filters:
            return .get
        case .like:
            return .post
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
        case .filters(let next, let limit, let category, let orderBy):
            var parms = ["order_by": orderBy]
            if !next.isEmpty { parms["next"] = next }
            if !limit.isEmpty { parms["limit"] = limit }
            if !category.isEmpty { parms["category"] = category }
            return parms
        case .like(_, let liked):
            return ["like_status": liked]
        }
    }
    
    var encoding: ParameterEncoding{
        switch self {
        case .todayFilter, .hotTrend, .filters:
            return URLEncoding.default
        case .like:
            return JSONEncoding.default
        }
    }
}
