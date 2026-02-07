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
    case otherProfile(userId: String)
    case deviceToken(deviceToken: String)
    case search(nick: String)
    
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
        case .otherProfile(let userId):
            return "/users/\(userId)/profile"
        case .deviceToken:
            return "/users/deviceToken"
        case .search:
            return "/users/search"
        }
    }
    
    var method: HTTPMethod{
        switch self {
        case .login, .apple:
            return .post
        case .auth, .todayAuthor, .otherProfile, .search:
            return .get
        case .deviceToken:
            return .put
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
        case .auth, .todayAuthor, .otherProfile:
            return nil
        case .apple(let idToken, let deviceToken):
            return ["idToken": idToken,
                    "deviceToken": deviceToken]
        case .deviceToken(let deviceToken):
            return ["deviceToken": deviceToken]
        case .search(let nick):
            return ["nick": nick]
        }
    }
    
    var encoding: ParameterEncoding{
        switch self {
        case .login, .auth, .apple, .otherProfile:
            return JSONEncoding.default
        case .todayAuthor, .deviceToken, .search:
            return URLEncoding.default
        }
    }
}
