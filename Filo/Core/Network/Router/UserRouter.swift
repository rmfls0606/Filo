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
    case getProfile //내 프로필 조회
    case putProfile(nick: String, name: String, introduction: String, phoneNum: String, profileImage: String, hashTags: [String]) //내 프로필 수정
    case image(profile: String)
    case logout
    
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
        case .getProfile, .putProfile:
            return "/users/me/profile"
        case .image:
            return "/users/profile/image"
        case .logout:
            return "/users/logout"
        }
    }
    
    var method: HTTPMethod{
        switch self {
        case .login, .apple, .image, .logout:
            return .post
        case .auth, .todayAuthor, .otherProfile, .search, .getProfile:
            return .get
        case .deviceToken, .putProfile:
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
        case .auth, .todayAuthor, .otherProfile, .getProfile, .logout:
            return nil
        case .apple(let idToken, let deviceToken):
            return ["idToken": idToken,
                    "deviceToken": deviceToken]
        case .deviceToken(let deviceToken):
            return ["deviceToken": deviceToken]
        case .search(let nick):
            return ["nick": nick]
        case .putProfile(let nick, let name, let introduction, let phoneNum, let profileImage, let hashTags):
            return ["nick": nick,
                    "name": name,
                    "introduction": introduction,
                    "phoneNum": phoneNum,
                    "profileImage": profileImage,
                    "hashTags": hashTags]
        case .image(let profile):
            return ["profile": profile]
        }
    }
    
    var encoding: ParameterEncoding{
        switch self {
        case .login, .auth, .apple, .otherProfile, .getProfile, .putProfile, .image:
            return JSONEncoding.default
        case .todayAuthor, .deviceToken, .search, .logout:
            return URLEncoding.default
        }
    }
}
