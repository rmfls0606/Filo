//
//  RefreshTokenResponseDTO.swift
//  Filo
//
//  Created by 이상민 on 1/29/26.
//

import Foundation

struct RefreshTokenResponseDTO: Decodable, Sendable{
    let accessToken: String
    let refreshToken: String
}
