//
//  UserRouter.swift
//  Filo
//
//  Created by 이상민 on 1/22/26.
//

import Alamofire

enum UserRouter: APITarget{
    case todayAuthor
    
    var path: String{
        switch self {
        case .todayAuthor:
            return "/users/today-author"
        }
    }
    
    var method: HTTPMethod{
        switch self {
        case .todayAuthor:
            return .get
        }
    }
    
    var headers: HTTPHeaders{
        return ["Authorization": NetworkConfig.authorization,
                "SeSACKey": NetworkConfig.apiKey]
    }
    
    var parameters: Parameters?{
        switch self {
        case .todayAuthor:
            return nil
        }
    }
    
    var encoding: ParameterEncoding{
        switch self {
        case .todayAuthor:
            return URLEncoding.default
        }
    }
}
