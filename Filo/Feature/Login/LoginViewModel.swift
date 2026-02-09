//
//  LoginViewModel.swift
//  Filo
//
//  Created by 이상민 on 1/26/26.
//

import Foundation
import RxSwift
import RxCocoa
import KakaoSDKUser
import KakaoSDKAuth

final class LoginViewModel: ViewModelType {
    private let disposeBag = DisposeBag()

    struct Input {
        let emailText: ControlProperty<String>
        let passwordText: ControlProperty<String>
        let loginTapped: Observable<Void>
        let kakaoLoginTapped: Observable<Void>
        let appleLoginToken: Observable<String>
    }

    struct Output {
        let loginEnabled: Driver<Bool>
        let loginSuccess: Driver<Void>
        let loginError: Driver<String>
        let isLoading: Driver<Bool>
    }

    func transform(input: Input) -> Output {
        let loginSuccessRelay = PublishRelay<Void>()
        let loginErrorRelay = PublishRelay<String>()
        let loadingRelay = BehaviorRelay<Bool>(value: false)

        let loginEnabled = Observable.combineLatest(
            input.emailText,
            input.passwordText
        )
        .map { email, password in
            !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        .distinctUntilChanged()
        .asDriver(onErrorJustReturn: false)

        input.loginTapped
            .withLatestFrom(Observable.combineLatest(input.emailText, input.passwordText))
            .subscribe(onNext: { email, password in
                let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
                loadingRelay.accept(true)
                Task {
                    defer {
                        Task { @MainActor in
                            loadingRelay.accept(false)
                        }
                    }
                    do {
                        let dto: LoginDTO = try await NetworkManager.shared.request(
                            UserRouter.login(email: trimmedEmail, password: password)
                        )
                        try await self.handleLoginSuccess(dto: dto)
                        loginSuccessRelay.accept(())
                    } catch let error as NetworkError {
                        loginErrorRelay.accept(error.localizedDescription)
                    }catch let error as KeychainError{
                        loginErrorRelay.accept(error.localizedDescription)
                    } catch {
                        loginErrorRelay.accept(error.localizedDescription)
                    }
                }
            })
            .disposed(by: disposeBag)
        
        input.kakaoLoginTapped
            .bind { [weak self] in
                guard let self else { return }
                let loginWithToken: (OAuthToken) -> Void = { token in
                    loadingRelay.accept(true)
                    Task {
                        defer {
                            Task { @MainActor in
                                loadingRelay.accept(false)
                            }
                        }
                        do {
                            let savedDeviceToken = UserDefaults.standard.string(forKey: "fcmToken") ?? ""
                            let deviceToken = savedDeviceToken.isEmpty ? NetworkConfig.apiKey : savedDeviceToken
                            let accessToken = token.accessToken
                            let dto = try await self.requestKakaoLogin(token: accessToken, deviceToken: deviceToken)
                            try await self.handleLoginSuccess(dto: dto)
                            loginSuccessRelay.accept(())
                        } catch let error as NetworkError {
                            loginErrorRelay.accept(error.errorDescription ?? "")
                        } catch let error as KeychainError {
                            loginErrorRelay.accept(error.localizedDescription)
                        } catch {
                            loginErrorRelay.accept(error.localizedDescription)
                        }
                    }
                }

                if UserApi.isKakaoTalkLoginAvailable() {
                    UserApi.shared.loginWithKakaoTalk { oauthToken, error in
                        if let error {
                            loginErrorRelay.accept(error.localizedDescription)
                            return
                        }
                        guard let oauthToken else { return }
                        loginWithToken(oauthToken)
                    }
                } else {
                    UserApi.shared.loginWithKakaoAccount { oauthToken, error in
                        if let error {
                            loginErrorRelay.accept(error.localizedDescription)
                            return
                        }
                        guard let oauthToken else { return }
                        loginWithToken(oauthToken)
                    }
                }
            }
            .disposed(by: disposeBag)

        input.appleLoginToken
            .subscribe(with: self) { owner, idToken in
                loadingRelay.accept(true)
                Task {
                    defer {
                        Task { @MainActor in
                            loadingRelay.accept(false)
                        }
                    }
                    do {
                        let savedDeviceToken = UserDefaults.standard.string(forKey: "fcmToken") ?? ""
                        let deviceToken = savedDeviceToken.isEmpty ? "" : savedDeviceToken
                        let dto: LoginDTO = try await NetworkManager.shared.request(
                            UserRouter.apple(idToken: idToken, deviceToken: deviceToken)
                        )
                        try await owner.handleLoginSuccess(dto: dto)
                        loginSuccessRelay.accept(())
                    } catch let error as NetworkError {
                        loginErrorRelay.accept(error.errorDescription ?? "")
                    } catch let error as KeychainError {
                        loginErrorRelay.accept(error.localizedDescription)
                    } catch {
                        loginErrorRelay.accept(error.localizedDescription)
                    }
                }
            }
            .disposed(by: disposeBag)

        return Output(
            loginEnabled: loginEnabled,
            loginSuccess: loginSuccessRelay.asDriver(onErrorDriveWith: .empty()),
            loginError: loginErrorRelay.asDriver(onErrorDriveWith: .empty()),
            isLoading: loadingRelay.asDriver()
        )
    }

    private func handleLoginSuccess(dto: LoginDTO) async throws {
        try await TokenStorage.shared.save(
            access: dto.accessToken,
            refresh: dto.refreshToken,
            userId: dto.userId
        )

        do {
            let profile: UserInfoResponseDTO = try await NetworkManager.shared.request(
                UserRouter.otherProfile(userId: dto.userId)
            )
            let name = (profile.name ?? profile.nick).trimmingCharacters(in: .whitespacesAndNewlines)
            if !name.isEmpty {
                try? await TokenStorage.shared.saveUserName(name)
            }
        } catch {
            // 프로필 조회 실패는 로그인 성공 흐름을 막지 않음
        }

        if let token = UserDefaults.standard.string(forKey: "fcmToken"), !token.isEmpty {
            do {
                try await NetworkManager.shared.requestEmpty(
                    UserRouter.deviceToken(deviceToken: token)
                )
            } catch {
            }
        }
    }

    private func requestKakaoLogin(token: String, deviceToken: String) async throws -> LoginDTO {
       
        do {
            return try await NetworkManager.shared.request(
                UserRouter.kakao(oauthToken: token, deviceToken: deviceToken)
            )
        } catch let error as NetworkError {
            print("[KakaoLogin] request failed: \(error)")
            throw error
        }
    }
}
