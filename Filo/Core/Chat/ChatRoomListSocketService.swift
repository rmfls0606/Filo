//
//  ChatRoomListSocketService.swift
//  Filo
//
//  Created by 이상민 on 2/7/26.
//

import Foundation

final class ChatRoomListSocketService {
    static let shared = ChatRoomListSocketService()

    private var managers: [String: ChatSocketManager] = [:]
    var onMessage: ((ChatResponseDTO) -> Void)?
    var onError: ((Error) -> Void)?

    private init() { }

    func connect(roomIds: [String]) {
        let targetSet = Set(roomIds)
        let existingSet = Set(managers.keys)

        for id in existingSet.subtracting(targetSet) {
            managers[id]?.disconnect()
            managers[id] = nil
        }

        for id in targetSet where managers[id] == nil {
            let manager = ChatSocketManager(roomId: id)
            manager.onMessage = { [weak self] message in
                self?.onMessage?(message)
            }
            manager.onError = { [weak self] error in
                self?.onError?(error)
            }
            managers[id] = manager
            manager.connect()
        }
    }

    func disconnectAll() {
        managers.values.forEach { $0.disconnect() }
        managers.removeAll()
    }
}
