//
//  ChatRoomListViewModel.swift
//  Filo
//
//  Created by 이상민 on 2/6/26.
//

import Foundation
import RxSwift
import RxCocoa

final class ChatRoomListViewModel: ViewModelType {
    private let service: ChatServiceProtocol
    private let localStore: ChatLocalStore
    private let socketService: ChatRoomListSocketService
    let currentUserId: String

    private let disposeBag = DisposeBag()
    private let userCacheTTL: TimeInterval = 60 * 60 * 24
    private let maxUserRefreshCount = 20

    init(currentUserId: String,
         service: ChatServiceProtocol = ChatService.shared,
         localStore: ChatLocalStore = .shared,
         socketService: ChatRoomListSocketService = .shared) {
        self.currentUserId = currentUserId
        self.service = service
        self.localStore = localStore
        self.socketService = socketService
    }

    struct Input {
        let viewWillAppear: Observable<Void>
        let viewWillDisappear: Observable<Void>
    }

    struct Output {
        let chatRoomList: Driver<[ChatRoomSummaryEntity]>
        let networkError: Signal<NetworkError>
    }

    func transform(input: Input) -> Output {
        let roomsRelay = BehaviorRelay<[ChatRoomSummaryEntity]>(value: localStore.fetchRoomSummaries())
        let errorRelay = PublishRelay<NetworkError>()

        input.viewWillAppear
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                // ChatRoom 화면에서 unread를 0으로 바꾼 값을
                // 목록 복귀 시 네트워크 대기 없이 즉시 반영한다.
                roomsRelay.accept(self.localStore.fetchRoomSummaries())
                Task {
                    do {
                        let rooms = try await self.service.fetchChatRooms()
                        let participants = rooms.flatMap { $0.participants }
                        self.localStore.upsertUsers(participants)
                        self.localStore.upsertRoomSummaries(from: rooms, currentUserId: self.currentUserId)
                        self.refreshUsersIfNeeded(rooms: rooms) { updated in
                            if updated {
                                roomsRelay.accept(self.localStore.fetchRoomSummaries())
                            }
                        }
                        roomsRelay.accept(self.localStore.fetchRoomSummaries())
                        let roomIds = rooms.map { $0.roomId }
                        self.socketService.connect(roomIds: roomIds)
                    } catch let error as NetworkError {
                        errorRelay.accept(error)
                    } catch {
                        errorRelay.accept(NetworkError.unknown(error))
                    }
                }
            })
            .disposed(by: disposeBag)

        input.viewWillDisappear
            .subscribe(onNext: { [weak self] in
                self?.socketService.disconnectAll()
            })
            .disposed(by: disposeBag)

        socketService.onMessage = { [weak self] message in
            guard let self else { return }
            let isCurrentRoom = CurrentChatRoom.shared.roomId == message.roomId
            self.localStore.upsertMessages([message])
            self.localStore.updateRoomSummary(with: message, currentUserId: self.currentUserId, isCurrentRoom: isCurrentRoom)
            roomsRelay.accept(self.localStore.fetchRoomSummaries())
        }

        return Output(
            chatRoomList: roomsRelay.asDriver(),
            networkError: errorRelay.asSignal()
        )
    }

    private func refreshUsersIfNeeded(rooms: [ChatRoomResponseDTO], completion: ((Bool) -> Void)? = nil) {
        let opponentIds = rooms.compactMap { room in
            room.participants.first(where: { $0.userID != currentUserId })?.userID
        }
        var stale = localStore.staleUserIds(opponentIds, ttl: userCacheTTL)
        stale.append(contentsOf: opponentIds)
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
