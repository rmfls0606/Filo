//
//  ProfileViewModel.swift
//  Filo
//
//  Created by 이상민 on 2/8/26.
//

import Foundation
import RxSwift
import RxCocoa

final class ProfileViewModel: ViewModelType {
    struct Input {
        let viewWillAppear: Observable<Void>
        let logoutTap: Observable<Void>
    }
    
    struct Output {
        let profileItem: Driver<MyInfoResponseDTO?>
        let logoutSuccess: Signal<Void>
        let networkError: Signal<NetworkError>
        let isLoading: Driver<Bool>
    }
    
    private let service: NetworkManagerProtocol
    private let disposeBag = DisposeBag()
    
    init(service: NetworkManagerProtocol = NetworkManager.shared) {
        self.service = service
    }
    
    func transform(input: Input) -> Output {
        let profileRelay = BehaviorRelay<MyInfoResponseDTO?>(value: nil)
        let logoutSuccessRelay = PublishRelay<Void>()
        let errorRelay = PublishRelay<NetworkError>()
        let loadingRelay = BehaviorRelay<Bool>(value: false)
        
        input.viewWillAppear
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                loadingRelay.accept(true)
                Task {
                    defer {
                        Task { @MainActor in
                            loadingRelay.accept(false)
                        }
                    }
//                    let currentUserId = (try? KeychainManager.shared.read(key: .userId)) ?? ""
//                    guard !currentUserId.isEmpty else { return }
                    do {
                        let dto: MyInfoResponseDTO = try await self.service.request(
                            UserRouter.getProfile
                        )
                        profileRelay.accept(dto)
                    } catch let error as NetworkError {
                        errorRelay.accept(error)
                    } catch {
                        errorRelay.accept(.unknown(error))
                    }
                }
            })
            .disposed(by: disposeBag)
        
        input.logoutTap
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                loadingRelay.accept(true)
                Task {
                    defer {
                        Task { @MainActor in
                            loadingRelay.accept(false)
                        }
                    }
                    do {
                        try await self.service.requestEmpty(UserRouter.logout)
                        await TokenStorage.shared.clear()
                        await MainActor.run {
                            logoutSuccessRelay.accept(())
                        }
                    } catch let error as NetworkError {
                        await MainActor.run {
                            errorRelay.accept(error)
                        }
                    } catch {
                        await MainActor.run {
                            errorRelay.accept(.unknown(error))
                        }
                    }
                }
            })
            .disposed(by: disposeBag)
        
        return Output(
            profileItem: profileRelay.asDriver(onErrorDriveWith: .empty()),
            logoutSuccess: logoutSuccessRelay.asSignal(),
            networkError: errorRelay.asSignal(),
            isLoading: loadingRelay.asDriver()
        )
    }
}
