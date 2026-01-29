//
//  LoginViewModel.swift
//  Filo
//
//  Created by 이상민 on 1/26/26.
//

import Foundation
import RxSwift
import RxCocoa

final class LoginViewModel: ViewModelType {
    private let disposeBag = DisposeBag()

    struct Input {
        let emailText: ControlProperty<String>
        let passwordText: ControlProperty<String>
        let loginTapped: ControlEvent<()>
    }

    struct Output {
        let loginEnabled: Driver<Bool>
        let loginSuccess: Driver<Void>
        let loginError: Driver<String>
    }

    func transform(input: Input) -> Output {
        let loginSuccessRelay = PublishRelay<Void>()
        let loginErrorRelay = PublishRelay<String>()

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
                Task {
                    do {
                        let dto: LoginDTO = try await NetworkManager.shared.request(
                            UserRouter.login(email: trimmedEmail, password: password)
                        )
                        try await TokenStorage.shared.save(
                            access: dto.accessToken,
                            refresh: dto.refreshToken,
                            userId: dto.userId
                        )
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

        return Output(
            loginEnabled: loginEnabled,
            loginSuccess: loginSuccessRelay.asDriver(onErrorDriveWith: .empty()),
            loginError: loginErrorRelay.asDriver(onErrorDriveWith: .empty())
        )
    }
}
