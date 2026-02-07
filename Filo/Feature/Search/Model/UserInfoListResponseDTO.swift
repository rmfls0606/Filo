//
//  UserInfoListResponseDTO.swift
//  Filo
//
//  Created by 이상민 on 2/7/26.
//

import Foundation

struct UserInfoListResponseDTO: Decodable, Sendable{
    let data: [UserInfoResponseDTO]
}
