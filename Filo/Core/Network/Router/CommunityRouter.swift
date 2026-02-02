//
//  CommunityRouter.swift
//  Filo
//
//  Created by 이상민 on 2/3/26.
//

import Alamofire

enum CommunityRouter: APITarget{
    case user(category: String, limit: String, next: String, userId: String)
    
    var path: String{
        switch self {
        case .user(_, _, _, let userId):
            return "/posts/users/\(userId)"
        }
    }
    
    var method: HTTPMethod{
        switch self {
        case .user:
            return .get
        }
    }
    
    var headers: HTTPHeaders{
        return ["Authorization": NetworkConfig.authorization,
                "SeSACKey": NetworkConfig.apiKey]
    }
    
    var parameters: Parameters?{
        switch self {
        case .user(let category, let limit, let next, _):
            var parms = [String: Any]()
            if !category.isEmpty { parms["category"] = category }
            if !category.isEmpty { parms["category"] = category }
            if !next.isEmpty { parms["next"] = next }
            return parms
        }
    }
    
    var encoding: ParameterEncoding{
        switch self {
        case .user:
            return URLEncoding.default
        }
    }
}

