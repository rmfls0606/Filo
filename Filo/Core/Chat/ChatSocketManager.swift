//
//  ChatSocketManager.swift
//  Filo
//
//  Created by 이상민 on 2/6/26.
//

import Foundation
import SocketIO

final class ChatSocketManager {
    enum State {
        case disconnected
        case connecting
        case connected
    }

    private let roomId: String
    private var manager: SocketManager?
    private var socket: SocketIOClient?

    var onMessage: ((ChatResponseDTO) -> Void)?
    var onError: ((Error) -> Void)?
    var onStateChange: ((State) -> Void)?

    private(set) var state: State = .disconnected {
        didSet { onStateChange?(state) }
    }

    init(roomId: String) {
        self.roomId = roomId
    }

    func connect() {
        guard state == .disconnected else { return }
        guard let baseURL = makeBaseURL() else { return }

        let headers: [String: String] = [
            "SeSACKey": NetworkConfig.apiKey,
            "Authorization": NetworkConfig.authorization
        ]

        state = .connecting
        let manager = SocketManager(socketURL: baseURL, config: [
            .log(false),
            .compress,
            .extraHeaders(headers),
            .forceWebsockets(true)
        ])
        self.manager = manager
        let namespace = "/chats-\(roomId)"
        let socket = manager.socket(forNamespace: namespace)
        self.socket = socket

        socket.on(clientEvent: .connect) { [weak self] _, _ in
            self?.state = .connected
        }

        socket.on(clientEvent: .disconnect) { [weak self] _, _ in
            self?.state = .disconnected
        }

        socket.on(clientEvent: .error) { [weak self] data, _ in
            self?.onError?(SocketClientError(data: data))
        }

        socket.on("chat") { [weak self] dataArray, _ in
            guard let self else { return }
            if let entity = self.decodeMessage(dataArray) {
                self.onMessage?(entity)
            }
        }

        socket.connect()
    }

    func disconnect() {
        socket?.disconnect()
        socket = nil
        manager = nil
        state = .disconnected
    }

    private func decodeMessage(_ dataArray: [Any]) -> ChatResponseDTO? {
        guard let dict = dataArray.first as? [String: Any] else { return nil }
        guard let data = try? JSONSerialization.data(withJSONObject: dict) else { return nil }
        do {
            let dto = try JSONDecoder().decode(ChatResponseDTO.self, from: data)
            return dto
        } catch {
            return nil
        }
    }

    private func makeBaseURL() -> URL? {
        let base = NetworkConfig.socketBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return URL(string: base)
    }
}

struct SocketClientError: LocalizedError {
    let data: [Any]

    var errorDescription: String? {
        if let first = data.first as? String {
            return first
        }
        return "소켓 오류가 발생했습니다."
    }
}
