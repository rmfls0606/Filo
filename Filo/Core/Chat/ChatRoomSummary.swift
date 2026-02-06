//
//  ChatRoomSummary.swift
//  Filo
//
//  Created by 이상민 on 2/7/26.
//

import Foundation
import RealmSwift

struct ChatRoomSummaryEntity {
    let roomId: String
    let opponentId: String?
    let lastMessage: String
    let lastMessageAt: String
    let unreadCount: Int
}

final class ChatRoomSummaryObject: Object {
    @Persisted(primaryKey: true) var roomId: String
    @Persisted var opponentId: String?
    @Persisted var lastMessage: String
    @Persisted var lastMessageAt: String
    @Persisted var unreadCount: Int

    func toEntity() -> ChatRoomSummaryEntity {
        ChatRoomSummaryEntity(
            roomId: roomId,
            opponentId: opponentId,
            lastMessage: lastMessage,
            lastMessageAt: lastMessageAt,
            unreadCount: unreadCount
        )
    }
}
