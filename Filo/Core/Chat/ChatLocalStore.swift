//
//  ChatLocalStore.swift
//  Filo
//
//  Created by 이상민 on 2/6/26.
//

import Foundation
import RealmSwift

final class ChatMessageObject: Object {
    @Persisted(primaryKey: true) var chatId: String
    @Persisted var roomId: String
    @Persisted var content: String
    @Persisted var createdAt: String
    @Persisted var updatedAt: String

    @Persisted var senderId: String
    @Persisted var senderNick: String
    @Persisted var senderName: String?
    @Persisted var senderIntro: String?
    @Persisted var senderProfileImage: String?
    @Persisted var senderHashTags: List<String>

    @Persisted var files: List<String>

    convenience init(dto: ChatResponseDTO) {
        self.init()
        chatId = dto.chatId
        roomId = dto.roomId
        content = dto.content
        createdAt = dto.createdAt
        updatedAt = dto.updatedAt
        senderId = dto.sender.userID
        senderNick = dto.sender.nick
        senderName = dto.sender.name
        senderIntro = dto.sender.introduction
        senderProfileImage = dto.sender.profileImage
        senderHashTags.append(objectsIn: dto.sender.hashTags)
        files.append(objectsIn: dto.files)
    }

    func toDTO() -> ChatResponseDTO {
        let sender = UserInfoResponseDTO(
            userID: senderId,
            nick: senderNick,
            name: senderName,
            introduction: senderIntro,
            profileImage: senderProfileImage,
            hashTags: Array(senderHashTags)
        )

        return ChatResponseDTO(
            chatId: chatId,
            roomId: roomId,
            content: content,
            createdAt: createdAt,
            updatedAt: updatedAt,
            sender: sender,
            files: Array(files)
        )
    }
}

final class ChatLocalStore {
    static let shared = ChatLocalStore()
    private let queue = DispatchQueue(label: "chat.local.store")

    private init() { }

    func fetchMessages(roomId: String) -> [ChatResponseDTO] {
        queue.sync {
            guard let realm = try? Realm() else { return [] }
            let results = realm.objects(ChatMessageObject.self)
                .where { $0.roomId == roomId }
                .sorted(byKeyPath: "createdAt", ascending: true)
            return results.map { $0.toDTO() }
        }
    }

    func latestMessage(roomId: String) -> ChatResponseDTO? {
        queue.sync {
            guard let realm = try? Realm() else { return nil }
            let object = realm.objects(ChatMessageObject.self)
                .where { $0.roomId == roomId }
                .sorted(byKeyPath: "createdAt", ascending: false)
                .first
            return object?.toDTO()
        }
    }

    func upsertMessages(_ messages: [ChatResponseDTO]) {
        guard !messages.isEmpty else { return }
        queue.sync {
            guard let realm = try? Realm() else { return }
            let objects = messages.map { ChatMessageObject(dto: $0) }
            do {
                try realm.write {
                    realm.add(objects, update: .modified)
                }
            } catch {
                return
            }
        }
    }
}
