//
//  ChatSocketService.swift
//  Filo
//
//  Created by 이상민 on 2/6/26.
//

import Foundation

final class ChatSocketService {
    static let shared = ChatSocketService()

    private var currentRoomId: String?
    private var manager: ChatSocketManager?

    var onMessage: ((ChatResponseDTO) -> Void)?
    var onError: ((Error) -> Void)?
    var onStateChange: ((ChatSocketManager.State) -> Void)?

    private init() { }

    func connect(roomId: String) {
        if currentRoomId == roomId, let manager, manager.state != .disconnected {
            return
        }

        disconnect()

        let manager = ChatSocketManager(roomId: roomId)
        manager.onMessage = { [weak self] message in
            self?.onMessage?(message)
        }
        manager.onError = { [weak self] error in
            self?.onError?(error)
        }
        manager.onStateChange = { [weak self] state in
            self?.onStateChange?(state)
        }

        currentRoomId = roomId
        self.manager = manager
        manager.connect()
    }

    func disconnect() {
        manager?.disconnect()
        manager = nil
        currentRoomId = nil
    }
}
