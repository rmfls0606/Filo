//
//  ChatLocalStore.swift
//  Filo
//
//  Created by 이상민 on 2/6/26.
//

import Foundation
import RealmSwift

final class ChatUserObject: Object {
    @Persisted(primaryKey: true) var userId: String
    @Persisted var nick: String
    @Persisted var name: String?
    @Persisted var introduction: String?
    @Persisted var profileImage: String?
    @Persisted var hashTags: List<String>
    @Persisted var lastFetchedAt: Date

    convenience init(dto: UserInfoResponseDTO, fetchedAt: Date = Date()) {
        self.init()
        userId = dto.userID
        nick = dto.nick
        name = dto.name
        introduction = dto.introduction
        profileImage = dto.profileImage
        hashTags.append(objectsIn: dto.hashTags)
        lastFetchedAt = fetchedAt
    }

    func toDTO() -> UserInfoResponseDTO {
        UserInfoResponseDTO(
            userID: userId,
            nick: nick,
            name: name,
            introduction: introduction,
            profileImage: profileImage,
            hashTags: Array(hashTags)
        )
    }
}

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
            let dtos = results.map { $0.toDTO() }
            let cached = fetchUserCache(ids: dtos.map { $0.sender.userID }, realm: realm)
            return dtos.map { dto in
                guard let sender = cached[dto.sender.userID] else { return dto }
                return ChatResponseDTO(
                    chatId: dto.chatId,
                    roomId: dto.roomId,
                    content: dto.content,
                    createdAt: dto.createdAt,
                    updatedAt: dto.updatedAt,
                    sender: sender,
                    files: dto.files
                )
            }
        }
    }

    func latestMessage(roomId: String) -> ChatResponseDTO? {
        queue.sync {
            guard let realm = try? Realm() else { return nil }
            let object = realm.objects(ChatMessageObject.self)
                .where { $0.roomId == roomId }
                .sorted(byKeyPath: "createdAt", ascending: false)
                .first
            guard let dto = object?.toDTO() else { return nil }
            let cached = fetchUserCache(ids: [dto.sender.userID], realm: realm)
            if let sender = cached[dto.sender.userID] {
                return ChatResponseDTO(
                    chatId: dto.chatId,
                    roomId: dto.roomId,
                    content: dto.content,
                    createdAt: dto.createdAt,
                    updatedAt: dto.updatedAt,
                    sender: sender,
                    files: dto.files
                )
            }
            return dto
        }
    }

    func upsertMessages(_ messages: [ChatResponseDTO]) {
        guard !messages.isEmpty else { return }
        queue.sync {
            guard let realm = try? Realm() else { return }
            let objects = messages.map { ChatMessageObject(dto: $0) }
            let uniqueUsers = Dictionary(grouping: messages, by: { $0.sender.userID })
                .compactMap { $0.value.first?.sender }
                .map { ChatUserObject(dto: $0) }
            do {
                try realm.write {
                    realm.add(objects, update: .modified)
                    realm.add(uniqueUsers, update: .modified)
                }
            } catch {
                return
            }
        }
    }

    func upsertRoomSummaries(from rooms: [ChatRoomResponseDTO], currentUserId: String) {
        guard !rooms.isEmpty else { return }
        queue.sync {
            guard let realm = try? Realm() else { return }
            do {
                try realm.write {
                    for room in rooms {
                        let object = realm.object(ofType: ChatRoomSummaryObject.self, forPrimaryKey: room.roomId)
                            ?? ChatRoomSummaryObject()
                        if object.roomId.isEmpty {
                            object.roomId = room.roomId
                        }
                        if object.opponentId == nil {
                            object.opponentId = room.participants.first { $0.userID != currentUserId }?.userID
                        }
                        let incomingMessageAt = room.lastChat?.createdAt ?? room.updatedAt
                        if incomingMessageAt > object.lastMessageAt {
                            object.lastMessageAt = incomingMessageAt
                            object.lastMessage = room.lastChat?.content ?? ""
                        }
                        realm.add(object, update: .modified)
                    }
                }
            } catch {
                return
            }
        }
    }

    func updateRoomSummary(with message: ChatResponseDTO, currentUserId: String, isCurrentRoom: Bool) {
        queue.sync {
            guard let realm = try? Realm() else { return }
            do {
                try realm.write {
                    let object = realm.object(ofType: ChatRoomSummaryObject.self, forPrimaryKey: message.roomId)
                        ?? ChatRoomSummaryObject()
                    if object.roomId.isEmpty {
                        object.roomId = message.roomId
                    }
                    if object.opponentId == nil, message.sender.userID != currentUserId {
                        object.opponentId = message.sender.userID
                    }
                    object.lastMessage = message.content
                    object.lastMessageAt = message.createdAt
                    if isCurrentRoom {
                        object.unreadCount = 0
                    } else if message.sender.userID != currentUserId {
                        object.unreadCount = min(300, object.unreadCount + 1)
                    }
                    realm.add(object, update: .modified)
                }
            } catch {
                return
            }
        }
    }

    func resetUnread(roomId: String) {
        queue.sync {
            guard let realm = try? Realm() else { return }
            guard let object = realm.object(ofType: ChatRoomSummaryObject.self, forPrimaryKey: roomId) else { return }
            do {
                try realm.write {
                    object.unreadCount = 0
                }
            } catch {
                return
            }
        }
    }

    func fetchRoomSummaries() -> [ChatRoomSummaryEntity] {
        queue.sync {
            guard let realm = try? Realm() else { return [] }
            let results = realm.objects(ChatRoomSummaryObject.self)
                .sorted(byKeyPath: "lastMessageAt", ascending: false)
            return results.map { $0.toEntity() }
        }
    }

    func upsertUsers(_ users: [UserInfoResponseDTO]) {
        guard !users.isEmpty else { return }
        queue.sync {
            guard let realm = try? Realm() else { return }
            let objects = users.map { ChatUserObject(dto: $0) }
            do {
                try realm.write {
                    realm.add(objects, update: .modified)
                }
            } catch {
                return
            }
        }
    }

    func fetchUser(userId: String) -> UserInfoResponseDTO? {
        queue.sync {
            guard let realm = try? Realm() else { return nil }
            guard let user = realm.object(ofType: ChatUserObject.self, forPrimaryKey: userId) else { return nil }
            return user.toDTO()
        }
    }

    func fetchUsers(userIds: [String]) -> [String: UserInfoResponseDTO] {
        guard !userIds.isEmpty else { return [:] }
        return queue.sync {
            guard let realm = try? Realm() else { return [:] }
            let results = realm.objects(ChatUserObject.self)
                .filter("userId IN %@", Array(Set(userIds)))
            var map: [String: UserInfoResponseDTO] = [:]
            for user in results {
                map[user.userId] = user.toDTO()
            }
            return map
        }
    }

    func staleUserIds(_ ids: [String], ttl: TimeInterval) -> [String] {
        guard !ids.isEmpty else { return [] }
        return queue.sync {
            guard let realm = try? Realm() else { return [] }
            let now = Date()
            let results = realm.objects(ChatUserObject.self)
                .filter("userId IN %@", ids)
            var stale: [String] = []
            let existing = Set(results.map { $0.userId })

            for id in ids where !existing.contains(id) {
                stale.append(id)
            }
            for user in results {
                if now.timeIntervalSince(user.lastFetchedAt) > ttl {
                    stale.append(user.userId)
                }
            }
            return Array(Set(stale))
        }
    }

    private func fetchUserCache(ids: [String], realm: Realm) -> [String: UserInfoResponseDTO] {
        guard !ids.isEmpty else { return [:] }
        let results = realm.objects(ChatUserObject.self)
            .filter("userId IN %@", Array(Set(ids)))
        var map: [String: UserInfoResponseDTO] = [:]
        for user in results {
            map[user.userId] = user.toDTO()
        }
        return map
    }
}
