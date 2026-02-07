//
//  CommunityRouter.swift
//  Filo
//
//  Created by 이상민 on 2/3/26.
//

import Alamofire

enum CommunityRouter: APITarget{
    case files(files: [String]) //jpg, png, jepg 최대 2개
    case posts(category: String, title: String, content: String, latitude: Double = 37.654215, longitude: Double = 127.049914, files: [String]) //게시글 작성
    case geolocation(category: String, longitude: String, latitude: String, maxDistance: String, limit: String, next: String, orderBy: String) //(위치 기반) 게시글 조회
    case search(title: String)
    case detail(postId: String)
    case put(postId: String, category: String, title: String, content: String, latitude: Double = 37.654215, longitude: Double = 127.049914, files: [String])
    case delete(postId: String)
    case like(postId: String, isLike: Bool)
    case user(category: String, limit: String, next: String, userId: String)
    case me(category: String, limit: String, next: String)
    
    var path: String{
        switch self {
        case .files:
            return "/posts/files"
        case .posts:
            return "/posts"
        case .geolocation:
            return "/posts/geolocation"
        case .search:
            return "/posts/search"
        case .detail(let postId), .put(let postId, _, _, _, _, _, _), .delete(let postId):
            return "/posts/\(postId)"
        case .like(let postId, _):
            return "/posts/\(postId)/like"
        case .user(_, _, _, let userId):
            return "/posts/users/\(userId)"
        case .me:
            return "/posts/likes/me"
        }
    }
    
    var method: HTTPMethod{
        switch self {
        case .files, .posts, .like:
            return .post
        case .user, .geolocation, .search, .detail, .me:
            return .get
        case .put:
            return .put
        case .delete:
            return .delete
        }
    }
    
    var headers: HTTPHeaders{
        return ["Authorization": NetworkConfig.authorization,
                "SeSACKey": NetworkConfig.apiKey]
    }
    
    var parameters: Parameters?{
        switch self {
        case .files, .detail, .delete:
            return nil
        case .put(_, let category, let title, let content, let latitude, let longitude, let files):
            return ["category": category,
                    "title": title,
                    "content": content,
                    "latitude": latitude,
                    "longitude": longitude,
                    "files": files
            ]
        case .posts(let cateogry, let title, let content, let latitude, let longitude, let files):
            return ["category": cateogry,
                    "title": title,
                    "content": content,
                    "latitude": latitude,
                    "longitude": longitude,
                    "files": files
            ]
        case .geolocation(let category, let longitude, let latitude, let maxDistance, let limit, let next, let orderBy):
            var parms = [String: Any]()
            if !category.isEmpty{ parms["category"] = category }
            if !longitude.isEmpty{ parms["longitude"] = longitude }
            if !latitude.isEmpty{ parms["latitude"] = latitude}
            if !maxDistance.isEmpty{ parms["maxDistance"] = maxDistance }
            if !limit.isEmpty{ parms["limit"] = maxDistance }
            if !next.isEmpty { parms["next"] = next }
            parms["order_by"] = orderBy
            return parms
        case .search(let title):
            return ["title": title]
        case .like(_, let isLike):
            return ["like_status": isLike]
        case .user(let category, let limit, let next, _):
            var parms = [String: Any]()
            if !category.isEmpty { parms["category"] = category }
            if !limit.isEmpty { parms["limit"] = limit }
            if !next.isEmpty { parms["next"] = next }
            return parms
        case .me(let category, let limit, let next):
            var parms = [String: Any]()
            if !category.isEmpty { parms["category"] = category }
            if !limit.isEmpty { parms["limit"] = limit }
            if !next.isEmpty { parms["next"] = next }
            return parms
        }
    }
    
    var encoding: ParameterEncoding{
        switch self {
        case .files, .posts, .detail, .put, .like, .me:
            return JSONEncoding.default
        case .geolocation, .user, .delete, .search:
            return URLEncoding.default
        }
    }
}
