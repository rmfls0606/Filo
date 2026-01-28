//
//  UserRouter.swift
//  Filo
//
//  Created by 이상민 on 1/22/26.
//

import Alamofire

enum UserRouter: APITarget{
    case login(email: String, password: String)
    case todayAuthor
    
    var path: String{
        switch self {
        case .login:
            return "/users/login"
        case .todayAuthor:
            return "/users/today-author"
        }
    }
    
    var method: HTTPMethod{
        switch self {
        case .login:
            return .post
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
        case .login(let email, let password):
            return ["email": email,
                    "password": password,
                    "deviceToken": NetworkConfig.apiKey]
        case .todayAuthor:
            return nil
        }
    }
    
    var encoding: ParameterEncoding{
        switch self {
        case .login:
            return JSONEncoding.default
        case .todayAuthor:
            return URLEncoding.default
        }
    }
}
