//
//  UserRouter.swift
//  Filo
//
//  Created by 이상민 on 1/22/26.
//

import Alamofire

enum UserRouter: APITarget{
    case login(email: String, password: String)
    case auth(refresh: String)
    case todayAuthor
    
    var path: String{
        switch self {
        case .login:
            return "/users/login"
        case .auth:
            return "/auth/refresh"
        case .todayAuthor:
            return "/users/today-author"
        }
    }
    
    var method: HTTPMethod{
        switch self {
        case .login:
            return .post
        case .auth, .todayAuthor:
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
        case .auth(let refresh):
            return ["RefreshToken": refresh]
        case .todayAuthor:
            return nil
        }
    }
    
    var encoding: ParameterEncoding{
        switch self {
        case .login, .auth:
            return JSONEncoding.default
        case .todayAuthor:
            return URLEncoding.default
        }
    }
}
