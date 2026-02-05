//
//  ChatService.swift
//  Filo
//
//  Created by 이상민 on 2/6/26.
//

import Foundation

protocol ChatServiceProtocol {
    func fetchChatRooms() async throws -> [ChatRoomResponseDTO]
    func createOrFetchRoom(opponentId: String) async throws -> ChatRoomResponseDTO
    func fetchChats(roomId: String, next: String) async throws -> [ChatResponseDTO]
    func sendChat(roomId: String, content: String, files: [String]) async throws -> ChatResponseDTO
}

final class ChatService: ChatServiceProtocol {
    static let shared = ChatService()
    private init() { }

    func fetchChatRooms() async throws -> [ChatRoomResponseDTO] {
        let dto: ChatRoomListResponseDTO = try await NetworkManager.shared.request(ChatRouter.fetchChatRooms)
        return dto.data
    }

    func createOrFetchRoom(opponentId: String) async throws -> ChatRoomResponseDTO {
        let dto: ChatRoomResponseDTO = try await NetworkManager.shared.request(ChatRouter.chatRooms(opponentId: opponentId))
        return dto
    }

    func fetchChats(roomId: String, next: String) async throws -> [ChatResponseDTO] {
        let dto: ChatListResponseDTO = try await NetworkManager.shared.request(ChatRouter.fetchChats(roomId: roomId, next: next))
        return dto.data
    }

    func sendChat(roomId: String, content: String, files: [String]) async throws -> ChatResponseDTO {
        let dto: ChatResponseDTO = try await NetworkManager.shared.request(ChatRouter.sendChats(roomId: roomId, content: content, files: files))
        return dto
    }
}
