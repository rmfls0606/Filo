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
    case detailFilter(filterId: String)
    case createFilter(requestBody: CreateFilterRequestBody)
    case files
    case user(userId: String, next: String, limit: String, category: String)

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
        case .detailFilter(let filterId):
            return "/filters/\(filterId)"
        case .createFilter:
            return "/filters"
        case .files:
            return "/filters/files"
        case .user(let userId, _, _, _):
            return "/filters/users/\(userId)"
        }
    }
    
    var method: HTTPMethod{
        switch self {
        case .hotTrend, .todayFilter, .filters, .detailFilter, .user:
            return .get
        case .like, .createFilter, .files:
            return .post
        }
    }
    
    var headers: HTTPHeaders{
        return ["Authorization": NetworkConfig.authorization,
                "SeSACKey": NetworkConfig.apiKey]
    }
    
    var parameters: Parameters?{
        switch self {
        case .todayFilter, .hotTrend, .detailFilter, .files:
            return nil
        case .filters(let next, let limit, let category, let orderBy):
            var parms = ["order_by": orderBy]
            if !next.isEmpty { parms["next"] = next }
            if !limit.isEmpty { parms["limit"] = limit }
            if !category.isEmpty { parms["category"] = category }
            return parms
        case .like(_, let liked):
            return ["like_status": liked]
        case .createFilter(let requestBody):
            return requestBody.asParameters()
        case .user(_, let next, let limit, let category):
            var parms = [String: Any]()
            if !next.isEmpty { parms["next"] = next }
            if !limit.isEmpty { parms["limit"] = limit }
            if !category.isEmpty { parms["category"] = category }
            return parms
        }
    }
    
    var encoding: ParameterEncoding{
        switch self {
        case .todayFilter, .hotTrend, .filters, .user:
            return URLEncoding.default
        case .like, .detailFilter, .createFilter, .files:
            return JSONEncoding.default
        }
    }
}
