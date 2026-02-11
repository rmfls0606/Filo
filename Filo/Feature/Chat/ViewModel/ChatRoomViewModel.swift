//
//  ChatRoomViewModel.swift
//  Filo
//
//  Created by 이상민 on 2/6/26.
//

import Foundation
import RxSwift
import RxCocoa

final class ChatRoomViewModel: ViewModelType {
    private var roomId: String?
    private let opponentId: String?
    private let service: ChatServiceProtocol
    private let localStore: ChatLocalStore
    private let disposeBag = DisposeBag()

    private let currentUserIdValue: String
    private let socketService: ChatSocketService
    private var isSyncing = false
    private var pendingSocketMessages: [ChatResponseDTO] = []
    private var pendingSocketIds = Set<String>()
    private let userCacheTTL: TimeInterval = 60 * 60 * 24
    private let maxUserRefreshCount = 10

    init(roomId: String?,
         opponentId: String?,
         service: ChatServiceProtocol = ChatService.shared,
         localStore: ChatLocalStore = .shared,
         socketService: ChatSocketService = .shared) {
        self.roomId = roomId
        self.opponentId = opponentId
        self.service = service
        self.localStore = localStore
        self.socketService = socketService
        self.currentUserIdValue = (try? KeychainManager.shared.read(key: .userId)) ?? ""
    }
    
    var currentUserId: String {
        currentUserIdValue
    }

    var currentRoomId: String? {
        roomId
    }

    struct Input {
        let viewWillAppear: Observable<Void>
        let viewWillDisappear: Observable<Void>
        let sendTapped: Observable<Void>
        let textChanged: Observable<String>
        let addAttachments: Observable<[ChatAttachmentItem]>
        let removeAttachment: Observable<UUID>
        let attachMenuToggle: Observable<Void>
        let attachMenuSelected: Observable<ChatAttachMenuItem>
    }

    struct Output {
        let messageItems: Driver<[ChatMessageItem]>
        let isSendEnabled: Driver<Bool>
        let sendCompleted: Signal<Void>
        let networkError: Signal<NetworkError>
        let attachments: Driver<[ChatAttachmentItem]>
        let attachMenuItems: Driver<[ChatAttachMenuItem]>
        let isAttachMenuVisible: Driver<Bool>
    }

    func transform(input: Input) -> Output {
        let messagesRelay = BehaviorRelay<[ChatResponseDTO]>(value: [])
        let textRelay = BehaviorRelay<String>(value: "")
        let sendEnabledRelay = BehaviorRelay<Bool>(value: false)
        let sendCompletedRelay = PublishRelay<Void>()
        let errorRelay = PublishRelay<NetworkError>()
        let attachmentsRelay = BehaviorRelay<[ChatAttachmentItem]>(value: [])
        let attachMenuVisibleRelay = BehaviorRelay<Bool>(value: false)
        let attachMenuItemsRelay = BehaviorRelay<[ChatAttachMenuItem]>(value: ChatAttachMenuItem.allCases)
        let maxAttachmentCount = 5

        let loadMessages: () -> Void = { [weak self] in
            guard let self else { return }
            guard let roomId = self.roomId else { return }
            self.isSyncing = true
            self.connectSocket(messagesRelay: messagesRelay, errorRelay: errorRelay)

            let localMessages = self.localStore.fetchMessages(roomId: roomId)
            messagesRelay.accept(localMessages)
            self.refreshUsersIfNeeded(senderIds: localMessages.map { $0.sender.userID }, forceIds: opponentId.map { [$0] } ?? []) { [weak self] updated in
                guard let self, updated else { return }
                messagesRelay.accept(self.localStore.fetchMessages(roomId: roomId))
            }

            let latest = self.localStore.latestMessage(roomId: roomId)
            let next = latest?.createdAt ?? ""

            Task { [weak self] in
                guard let self else { return }
                do {
                    let serverMessages = try await self.service.fetchChats(roomId: roomId, next: next)
                    if !serverMessages.isEmpty {
                        self.localStore.upsertMessages(serverMessages)
                        if let latest = serverMessages.max(by: { $0.createdAt < $1.createdAt }) {
                            self.localStore.updateRoomSummary(with: latest, currentUserId: self.currentUserIdValue, isCurrentRoom: true)
                        }
                        messagesRelay.accept(self.localStore.fetchMessages(roomId: roomId))
                        self.refreshUsersIfNeeded(senderIds: serverMessages.map { $0.sender.userID }, forceIds: []) { [weak self] updated in
                            guard let self, updated else { return }
                            messagesRelay.accept(self.localStore.fetchMessages(roomId: roomId))
                        }
                    }
                    self.connectSocket(messagesRelay: messagesRelay, errorRelay: errorRelay)
                    let latestAfterSync = self.localStore.latestMessage(roomId: roomId)
                    let nextAfterSync = latestAfterSync?.createdAt ?? ""
                    let catchUp = try await self.service.fetchChats(roomId: roomId, next: nextAfterSync)
                    if !catchUp.isEmpty {
                        self.localStore.upsertMessages(catchUp)
                        if let latest = catchUp.max(by: { $0.createdAt < $1.createdAt }) {
                            self.localStore.updateRoomSummary(with: latest, currentUserId: self.currentUserIdValue, isCurrentRoom: true)
                        }
                        messagesRelay.accept(self.localStore.fetchMessages(roomId: roomId))
                        self.refreshUsersIfNeeded(senderIds: catchUp.map { $0.sender.userID }, forceIds: []) { [weak self] updated in
                            guard let self, updated else { return }
                            messagesRelay.accept(self.localStore.fetchMessages(roomId: roomId))
                        }
                    }
                    self.isSyncing = false
                    self.flushPendingMessages(roomId: roomId, messagesRelay: messagesRelay)
                } catch let error as NetworkError {
                    self.isSyncing = false
                    errorRelay.accept(error)
                } catch {
                    self.isSyncing = false
                    errorRelay.accept(NetworkError.unknown(error))
                }
            }
        }

        input.viewWillAppear
            .subscribe(onNext: { _ in
                loadMessages()
            })
            .disposed(by: disposeBag)

        input.viewWillDisappear
            .subscribe(onNext: { [weak self] in
                self?.disconnectSocket()
            })
            .disposed(by: disposeBag)

        input.textChanged
            .bind(to: textRelay)
            .disposed(by: disposeBag)

        input.attachMenuToggle
            .subscribe(onNext: {
                attachMenuVisibleRelay.accept(!attachMenuVisibleRelay.value)
            })
            .disposed(by: disposeBag)

        input.attachMenuSelected
            .subscribe(onNext: { _ in
                attachMenuVisibleRelay.accept(false)
            })
            .disposed(by: disposeBag)

        input.addAttachments
            .subscribe(onNext: { items in
                guard !items.isEmpty else { return }
                var current = attachmentsRelay.value
                let available = maxAttachmentCount - current.count
                guard available > 0 else { return }
                current.append(contentsOf: items.prefix(available))
                attachmentsRelay.accept(current)
            })
            .disposed(by: disposeBag)

        input.removeAttachment
            .subscribe(onNext: { id in
                let updated = attachmentsRelay.value.filter { $0.id != id }
                attachmentsRelay.accept(updated)
            })
            .disposed(by: disposeBag)

        let sendPayload = Observable
            .combineLatest(textRelay, attachmentsRelay)

        input.sendTapped
            .withLatestFrom(sendPayload)
            .subscribe(onNext: { [weak self] text, attachments in
                self?.sendMessage(text: text,
                                  attachments: attachments,
                                  attachmentsRelay: attachmentsRelay,
                                  messagesRelay: messagesRelay,
                                  sendCompletedRelay: sendCompletedRelay,
                                  errorRelay: errorRelay)
            })
            .disposed(by: disposeBag)

        Observable
            .combineLatest(textRelay, attachmentsRelay)
            .map { text, attachments in
                let hasText = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                return hasText || !attachments.isEmpty
            }
            .bind(to: sendEnabledRelay)
            .disposed(by: disposeBag)

        let itemsDriver = messagesRelay
            .map { [weak self] messages -> [ChatMessageItem] in
                guard let self else { return [] }
                return messages.map { ChatMessageItem(message: $0, isMine: $0.sender.userID == self.currentUserIdValue) }
            }
            .asDriver(onErrorJustReturn: [])

        return Output(
            messageItems: itemsDriver,
            isSendEnabled: sendEnabledRelay.asDriver(),
            sendCompleted: sendCompletedRelay.asSignal(),
            networkError: errorRelay.asSignal(),
            attachments: attachmentsRelay.asDriver(),
            attachMenuItems: attachMenuItemsRelay.asDriver(),
            isAttachMenuVisible: attachMenuVisibleRelay.asDriver()
        )
    }

    private func connectSocket(messagesRelay: BehaviorRelay<[ChatResponseDTO]>, errorRelay: PublishRelay<NetworkError>) {
        guard let roomId = roomId else { return }
        socketService.onMessage = { [weak self] message in
            guard let self else { return }
            if self.isSyncing {
                if !self.pendingSocketIds.contains(message.chatId) {
                    self.pendingSocketMessages.append(message)
                    self.pendingSocketIds.insert(message.chatId)
                }
            } else {
                self.localStore.upsertMessages([message])
                self.localStore.updateRoomSummary(with: message, currentUserId: self.currentUserIdValue, isCurrentRoom: true)
                messagesRelay.accept(self.localStore.fetchMessages(roomId: roomId))
            }
        }
        socketService.onError = { error in
            errorRelay.accept(NetworkError.unknown(error))
        }
        socketService.connect(roomId: roomId)
    }

    private func flushPendingMessages(roomId: String, messagesRelay: BehaviorRelay<[ChatResponseDTO]>) {
        guard !pendingSocketMessages.isEmpty else { return }
        localStore.upsertMessages(pendingSocketMessages)
        if let latest = pendingSocketMessages.max(by: { $0.createdAt < $1.createdAt }) {
            localStore.updateRoomSummary(with: latest, currentUserId: currentUserIdValue, isCurrentRoom: true)
        }
        messagesRelay.accept(localStore.fetchMessages(roomId: roomId))
        refreshUsersIfNeeded(senderIds: pendingSocketMessages.map { $0.sender.userID }, forceIds: []) { [weak self] updated in
            guard let self, updated else { return }
            messagesRelay.accept(self.localStore.fetchMessages(roomId: roomId))
        }
        pendingSocketMessages.removeAll()
        pendingSocketIds.removeAll()
    }

    private func disconnectSocket() {
        socketService.onMessage = nil
        socketService.onError = nil
        socketService.onStateChange = nil
        socketService.disconnect()
    }

    private func sendMessage(text: String,
                             attachments: [ChatAttachmentItem],
                             attachmentsRelay: BehaviorRelay<[ChatAttachmentItem]>,
                             messagesRelay: BehaviorRelay<[ChatResponseDTO]>,
                             sendCompletedRelay: PublishRelay<Void>,
                             errorRelay: PublishRelay<NetworkError>) {
        Task { [weak self] in
            guard let self else { return }
            do {
                if roomId == nil {
                    guard let opponentId else { return }
                    let created = try await self.service.createOrFetchRoom(opponentId: opponentId)
                    self.roomId = created.roomId
                }
                guard let roomId else { return }
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                let sendUnits = self.buildSendUnits(text: trimmed, attachments: attachments)
                guard !sendUnits.isEmpty else { return }

                var sentMessages: [ChatResponseDTO] = []
                for unit in sendUnits {
                    let uploadedFiles: [String]
                    if unit.attachments.isEmpty {
                        uploadedFiles = []
                    } else {
                        uploadedFiles = try await self.service.uploadFiles(roomId: roomId, items: unit.attachments)
                    }
                    let sent = try await self.service.sendChat(roomId: roomId, content: unit.content, files: uploadedFiles)
                    sentMessages.append(sent)
                }

                guard let lastSent = sentMessages.last else { return }
                self.localStore.upsertMessages(sentMessages)
                self.localStore.updateRoomSummary(with: lastSent, currentUserId: self.currentUserIdValue, isCurrentRoom: true)
                messagesRelay.accept(self.localStore.fetchMessages(roomId: roomId))
                self.refreshUsersIfNeeded(senderIds: sentMessages.map { $0.sender.userID }, forceIds: []) { [weak self] updated in
                    guard let self, updated else { return }
                    messagesRelay.accept(self.localStore.fetchMessages(roomId: roomId))
                }
                attachmentsRelay.accept([])
                self.connectSocket(messagesRelay: messagesRelay, errorRelay: errorRelay)
                sendCompletedRelay.accept(())
            } catch let error as NetworkError {
                errorRelay.accept(error)
            } catch {
                errorRelay.accept(NetworkError.unknown(error))
            }
        }
    }

    private func buildSendUnits(text: String, attachments: [ChatAttachmentItem]) -> [(content: String, attachments: [ChatAttachmentItem])] {
        var units: [(content: String, attachments: [ChatAttachmentItem])] = []
        guard !attachments.isEmpty else {
            if !text.isEmpty {
                units.append((content: text, attachments: []))
            }
            return units
        }

        var grouped: [Bool: [ChatAttachmentItem]] = [:]
        var typeOrder: [Bool] = []
        for item in attachments {
            if grouped[item.isImage] == nil {
                grouped[item.isImage] = []
                typeOrder.append(item.isImage)
            }
            grouped[item.isImage]?.append(item)
        }

        for type in typeOrder {
            guard let items = grouped[type], !items.isEmpty else { continue }
            units.append((content: "(첨부파일)", attachments: items))
        }

        if !text.isEmpty {
            units.append((content: text, attachments: []))
        }

        return units
    }

    private func refreshUsersIfNeeded(senderIds: [String], forceIds: [String], completion: ((Bool) -> Void)? = nil) {
        let ids = Array(Set(senderIds + forceIds))
        var stale = localStore.staleUserIds(ids, ttl: userCacheTTL)
        stale.append(contentsOf: forceIds)
        stale = Array(Set(stale))
        guard !stale.isEmpty else { return }

        Task {
            var updated = false
            for userId in stale.prefix(maxUserRefreshCount) {
                do {
                    let dto: UserInfoResponseDTO = try await NetworkManager.shared.request(UserRouter.otherProfile(userId: userId))
                    localStore.upsertUsers([dto])
                    updated = true
                } catch {
                    continue
                }
            }
            if updated {
                completion?(true)
            }
        }
    }
}

struct ChatMessageItem {
    let message: ChatResponseDTO
    let isMine: Bool
}
