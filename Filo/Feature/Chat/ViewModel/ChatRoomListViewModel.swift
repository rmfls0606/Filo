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
    let currentUserId: String
    
    private let disposeBag = DisposeBag()

    init(currentUserId: String, service: ChatServiceProtocol = ChatService.shared) {
        self.currentUserId = currentUserId
        self.service = service
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
}
