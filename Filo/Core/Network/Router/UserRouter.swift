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
    case apple(idToken: String, deviceToken: String)
    
    var path: String{
        switch self {
        case .login:
            return "/users/login"
        case .auth:
            return "/auth/refresh"
        case .todayAuthor:
            return "/users/today-author"
        case .apple:
            return "/users/login/apple"
        }
    }
    
    var method: HTTPMethod{
        switch self {
        case .login, .apple:
            return .post
        case .auth, .todayAuthor:
            return .get
        }
    }
    
    var headers: HTTPHeaders{
        switch self{
        case .auth(let refresh):
            return ["RefreshToken": refresh,
                    "Authorization": NetworkConfig.authorization,
                    "SeSACKey": NetworkConfig.apiKey]
        default:
            return ["Authorization": NetworkConfig.authorization,
                    "SeSACKey": NetworkConfig.apiKey]
        }
    }
    
    var parameters: Parameters?{
        switch self {
        case .login(let email, let password):
            return ["email": email,
                    "password": password,
                    "deviceToken": NetworkConfig.apiKey]
        case .auth, .todayAuthor:
            return nil
        case .apple(let idToken, let deviceToken):
            return ["idToken": idToken,
                    "deviceToken": deviceToken]
        }
    }
    
    var encoding: ParameterEncoding{
        switch self {
        case .login, .auth, .apple:
            return JSONEncoding.default
        case .todayAuthor:
            return URLEncoding.default
        }
    }
}
