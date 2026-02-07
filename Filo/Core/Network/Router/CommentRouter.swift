//
//  CommentRouter.swift
//  Filo
//
//  Created by 이상민 on 2/7/26.
//

import Alamofire

enum CommentRouter: APITarget{
    case postComments(postId: String, parent_comment_id: String, content: String)
    case putComments(postId: String, commentId: String, content: String)
    case deleteComments(postId: String, commentId: String)
    
    var path: String{
        switch self {
        case .postComments(let postId, _, _):
            return "/posts/\(postId)/comments"
        case .putComments(let postId, let commentId, _):
            return "/posts/\(postId)/comments/\(commentId)"
        case .deleteComments(let postId, let commentId):
            return "/posts/\(postId)/comments/\(commentId)"
        }
    }
    
    var method: HTTPMethod{
        switch self {
        case .postComments:
            return .post
        case .putComments:
            return .put
        case .deleteComments:
            return .delete
        }
    }
    
    var headers: HTTPHeaders{
        return ["Authorization": NetworkConfig.authorization,
                "SeSACKey": NetworkConfig.apiKey]
    }
    
    var parameters: Parameters?{
        switch self {
        case .postComments(_, let parent_comment_id, let content):
            return ["parent_comment_id": parent_comment_id,
                    "content": content]
        case .putComments(_, _, let content):
            return ["content": content]
        case .deleteComments:
            return nil
        }
    }
    
    var encoding: ParameterEncoding{
        switch self {
        case .postComments, .putComments:
            return JSONEncoding.default
        case .deleteComments:
            return URLEncoding.default
        }
    }
}

