//
//  ChatRouter.swift
//  Filo
//
//  Created by 이상민 on 2/5/26.
//

import Alamofire

enum ChatRouter: APITarget{
    case chatRooms(opponentId: String) //채팅방 생성(조회), opponentId: 상대방 user_id
    case fetchChatRooms //채팅방 목록 조회
    case sendChats(roomId: String, content: String, files: [String]) //채팅 보내기
    case fetchChats(roomId: String, next: String) //채팅내역 목록 조회
    case files(roomId: String, files: [String]) //채팅방 파일 업로드(최대 5개) - jpg, png, jpeg, gif, pdf
    
    var path: String{
        switch self {
        case .chatRooms, .fetchChatRooms:
            return "/chats"
        case .sendChats(let roomId, _, _):
            return "/chats/\(roomId)"
        case .fetchChats(let roomId, _):
            return "/chats/\(roomId)"
        case .files(let roomId, _):
            return "/chats/\(roomId)/files"
        }
    }
    
    var method: HTTPMethod{
        switch self {
        case .chatRooms, .sendChats, .files:
            return .post
        case . fetchChatRooms, .fetchChats:
            return .get
        }
    }
    
    var headers: HTTPHeaders{
        return ["Authorization": NetworkConfig.authorization,
                "SeSACKey": NetworkConfig.apiKey]
    }
    
    var parameters: Parameters?{
        switch self {
        case .chatRooms(let opponentId):
            return ["opponent_id": opponentId]
        case .fetchChatRooms:
            return nil
        case .sendChats(_, let content, let files):
            return ["content": content,
                    "files": files]
        case .fetchChats(_, let next):
            if !next.isEmpty{
                return ["next": next]
            }else{
                return nil
            }
        case .files(_, let files):
            return ["files": files]
        }
    }
    
    var encoding: ParameterEncoding{
        switch self {
        case .chatRooms, .sendChats, .fetchChats, .files:
            return JSONEncoding.default
        case .fetchChatRooms:
            return URLEncoding.default
        }
    }
}

