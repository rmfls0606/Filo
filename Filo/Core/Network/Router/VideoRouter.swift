//
//  VideoRouter.swift
//  Filo
//
//  Created by 이상민 on 2/8/26.
//

import Alamofire

enum VideoRouter: APITarget{
    case videos(next: String, limit: Int)
    case stream(videoId: String)
    case like(videoId: String, likeStatus: Bool)
    
    var path: String{
        switch self {
        case .videos:
            return "/videos"
        case .stream(let videoId):
            return "/videos/\(videoId)/stream"
        case .like(let videoId, _):
            return "/videos/\(videoId)/like"
        }
    }
    
    var method: HTTPMethod{
        switch self {
        case .videos, .stream:
            return .get
        case .like:
            return .post
        }
    }
    
    var headers: HTTPHeaders{
        return ["Authorization": NetworkConfig.authorization,
                "SeSACKey": NetworkConfig.apiKey]
    }
    
    var parameters: Parameters?{
        switch self {
        case .videos(let next, let limit):
            var params: Parameters = ["limit": limit]
            if !next.isEmpty {
                params["next"] = next
            }
            return params
        case .stream:
            return nil
        case .like(_, let likeStatus):
            return ["like_status": likeStatus]
        }
    }
    
    var encoding: ParameterEncoding{
        switch self {
        case .videos, .stream:
            return URLEncoding.default
        case .like:
            return JSONEncoding.default
        }
    }
}
