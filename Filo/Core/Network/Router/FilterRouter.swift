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
    case likesMe(category: String, next: String, limit: String)
    case updateFilter(filterId: String, requestBody: CreateFilterRequestBody)
    case deleteFilter(filterId: String)

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
        case .likesMe:
            return "/filters/likes/me"
        case .updateFilter(let filterId, _):
            return "/filters/\(filterId)"
        case .deleteFilter(let filterId):
            return "/filters/\(filterId)"
        }
    }
    
    var method: HTTPMethod{
        switch self {
        case .hotTrend, .todayFilter, .filters, .detailFilter, .user, .likesMe:
            return .get
        case .like, .createFilter, .files:
            return .post
        case .updateFilter:
            return .put
        case .deleteFilter:
            return .delete
        }
    }
    
    var headers: HTTPHeaders{
        return ["Authorization": NetworkConfig.authorization,
                "SeSACKey": NetworkConfig.apiKey]
    }
    
    var parameters: Parameters?{
        switch self {
        case .todayFilter, .hotTrend, .detailFilter, .files, .deleteFilter:
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
        case .likesMe(let category, let next, let limit): //마지막 페이지 경우 next_cursor 응닶값은 "0"
            var parms = [String: Any]()
            if !next.isEmpty { parms["next"] = next }
            if !limit.isEmpty { parms["limit"] = limit }
            if !category.isEmpty { parms["category"] = category }
            return parms
        case .updateFilter(_, let requestBody):
            return requestBody.asParameters()
        }
    }
    
    var encoding: ParameterEncoding{
        switch self {
        case .todayFilter, .hotTrend, .filters, .user, .likesMe, .deleteFilter:
            return URLEncoding.default
        case .like, .detailFilter, .createFilter, .files, .updateFilter:
            return JSONEncoding.default
        }
    }
}
