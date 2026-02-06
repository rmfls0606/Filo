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
    let currentUserId: String

    private let disposeBag = DisposeBag()
    private let userCacheTTL: TimeInterval = 60 * 60 * 24
    private let maxUserRefreshCount = 20

    init(currentUserId: String,
         service: ChatServiceProtocol = ChatService.shared,
         localStore: ChatLocalStore = .shared) {
        self.currentUserId = currentUserId
        self.service = service
        self.localStore = localStore
    }

    struct Input {
        let viewWillAppear: Observable<Void>
    }

    struct Output {
        let chatRoomList: Driver<[ChatRoomResponseDTO]>
        let networkError: Signal<NetworkError>
    }

    func transform(input: Input) -> Output {
        let roomsRelay = BehaviorRelay<[ChatRoomResponseDTO]>(value: [])
        let errorRelay = PublishRelay<NetworkError>()

        input.viewWillAppear
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                Task {
                    do {
                        let rooms = try await self.service.fetchChatRooms()
                        let participants = rooms.flatMap { $0.participants }
                        self.localStore.upsertUsers(participants)
                        self.refreshUsersIfNeeded(rooms: rooms) { updated in
                            if updated {
                                roomsRelay.accept(roomsRelay.value)
                            }
                        }
                        roomsRelay.accept(rooms)
                    } catch let error as NetworkError {
                        errorRelay.accept(error)
                    } catch {
                        errorRelay.accept(NetworkError.unknown(error))
                    }
                }
            })
            .disposed(by: disposeBag)

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
