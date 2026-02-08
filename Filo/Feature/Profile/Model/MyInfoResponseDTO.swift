//
//  MyInfoResponseDTO.swift
//  Filo
//
//  Created by 이상민 on 2/8/26.
//

import Foundation

struct MyInfoResponseDTO: Decodable, Sendable{
    let userId: String
    let email: String
    let nick: String
    let name: String?
    let introduction: String?
    let profileImage: String?
    let phoneNum: String?
    let hashTags: [String]
    
    private enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case email
        case nick
        case name
        case introduction
        case profileImage
        case phoneNum
        case hashTags
    }
}
