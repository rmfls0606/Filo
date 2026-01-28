//
//  LoginDTO.swift
//  Filo
//
//  Created by 이상민 on 1/26/26.
//

import Foundation

struct LoginDTO: Decodable, Sendable{
    let userId: String
    let email: String
    let nick: String
    let profileImage: String?
    let accessToken: String
    let refreshToken: String
    
    private enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case email
        case nick
        case profileImage
        case accessToken
        case refreshToken = "refreshToken"
    }
}
