//
//  DeviceSecurityAuthenticator.swift
//  Filo
//
//  Created by Codex on 3/12/26.
//

import Foundation
import LocalAuthentication
import UIKit

enum DeviceSecurityAuthError: LocalizedError, Equatable {
    case unavailable
    case canceled
    case failed

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "기기 암호 또는 Face ID/Touch ID가 설정되어 있지 않습니다. 설정에서 기기 보안을 먼저 활성화해주세요."
        case .canceled:
            return "본인 인증이 취소되어 채팅에 접근할 수 없습니다."
        case .failed:
            return "본인 인증에 실패했습니다. 다시 시도해주세요."
        }
    }
}

final class DeviceSecurityAuthenticator {
    static let shared = DeviceSecurityAuthenticator()
    private let store = ChatLockSettingsStore.shared

    private init() { }

    @MainActor
    func authenticateForAppAccess(from presenter: UIViewController) async throws {
        let settings = store.settings()
        guard settings.isLockEnabled else { return }
        try await presentCustomPasscodeLock(
            from: presenter,
            title: "Filo 잠금",
            message: "Filo 암호를 입력해 주세요.",
            leadingAction: settings.isBiometricEnabled && store.canUseBiometrics() ? .biometric : .empty
        )
    }

    @MainActor
    func authenticateForChatListEntry(from presenter: UIViewController) async throws {
        try await authenticateForAppAccess(from: presenter)
    }

    @MainActor
    func authenticateForDirectChatRoomEntry(from presenter: UIViewController) async throws {
        try await authenticateForAppAccess(from: presenter)
    }

    @MainActor
    func authenticateWithAppPasscode(from presenter: UIViewController) async throws {
        try await presentCustomPasscodeLock(
            from: presenter,
            title: "암호 확인",
            message: "Filo 암호를 입력해 주세요.",
            leadingAction: .cancel
        )
    }

    private func authenticateWithBiometricsOnly(reason: String) async throws {
        let context = LAContext()
        context.localizedCancelTitle = "취소"
        context.localizedFallbackTitle = ""

        var authError: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) else {
            throw DeviceSecurityAuthError.unavailable
        }

        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
            guard success else {
                throw DeviceSecurityAuthError.failed
            }
        } catch let error as LAError {
            switch error.code {
            case .userCancel, .systemCancel, .appCancel:
                throw DeviceSecurityAuthError.canceled
            case .authenticationFailed, .userFallback:
                throw DeviceSecurityAuthError.failed
            case .biometryNotAvailable, .biometryNotEnrolled, .passcodeNotSet:
                throw DeviceSecurityAuthError.unavailable
            default:
                throw DeviceSecurityAuthError.failed
            }
        } catch {
            throw DeviceSecurityAuthError.failed
        }
    }

    @MainActor
    private func presentCustomPasscodeLock(
        from presenter: UIViewController,
        title: String,
        message: String,
        leadingAction: ChatLockEntryViewController.LeadingAction
    ) async throws {
        guard store.settings().hasPasscode else {
            throw DeviceSecurityAuthError.unavailable
        }

        let biometricHandler: (() async -> Result<Void, DeviceSecurityAuthError>)?
        if leadingAction == .biometric {
            biometricHandler = { [weak self] in
                guard let self else { return Result.failure(.failed) }
                do {
                    try await self.authenticateWithBiometricsOnly(reason: message)
                    return Result.success(())
                } catch let error as DeviceSecurityAuthError {
                    return Result.failure(error)
                } catch {
                    return Result.failure(.failed)
                }
            }
        } else {
            biometricHandler = nil
        }

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let controller = ChatLockEntryViewController(
                title: title,
                message: message,
                leadingAction: leadingAction,
                showsCloseButton: leadingAction == .cancel,
                verifyPasscode: { [weak self] passcode in
                    self?.store.verifyPasscode(passcode) ?? false
                },
                biometricAction: biometricHandler
            )

            controller.onSuccess = {
                continuation.resume()
            }
            controller.onCancel = {
                continuation.resume(throwing: DeviceSecurityAuthError.canceled)
            }

            presenter.present(controller, animated: true)
        }
    }
}
