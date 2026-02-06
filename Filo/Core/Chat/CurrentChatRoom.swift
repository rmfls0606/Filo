//
//  CurrentChatRoom.swift
//  Filo
//
//  Created by 이상민 on 2/7/26.
//

import Foundation

final class CurrentChatRoom {
    static let shared = CurrentChatRoom()
    private init() { }

    var roomId: String?
}
