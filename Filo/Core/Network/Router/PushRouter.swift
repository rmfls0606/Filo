//
//  PushRouter.swift
//  Filo
//
//  Created by 이상민 on 2/7/26.
//

import Alamofire

enum PushRouter: APITarget{
    case push(userId: String, title: String, subTitle: String, body: String)
    
    var path: String{
        switch self {
        case .push:
            return "/notifications/push"
        }
    }
    
    var method: HTTPMethod{
        switch self {
        case .push:
            return .post
        }
    }
    
    var headers: HTTPHeaders{
        return ["Authorization": NetworkConfig.authorization,
                "SeSACKey": NetworkConfig.apiKey]
    }
    
    var parameters: Parameters?{
        switch self {
        case .push(let userId, let title, let subTitle, let body):
            return ["user_id": userId,
                    "title": title,
                    "subtitle": subTitle,
                    "body": body]
        }
    }
    
    var encoding: ParameterEncoding{
        switch self {
        case .push:
            return JSONEncoding.default
        }
    }
}

