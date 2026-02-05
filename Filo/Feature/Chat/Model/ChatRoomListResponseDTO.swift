//
//  ChatRoomListResponseDTO.swift
//  Filo
//
//  Created by 이상민 on 2/5/26.
//

import Foundation

struct ChatRoomListResponseDTO: Decodable, Sendable{
    let data: [ChatRoomResponseDTO]
}
