//
//  SessionExpiryHandler.swift
//  Filo
//
//  Created by 이상민 on 2/8/26.
//

import UIKit

final class SessionExpiryHandler {
    static let shared = SessionExpiryHandler()

    @MainActor
    private var isPresenting = false

    private init() {}

    func handleSessionExpired() async {
        await MainActor.run {
            guard !isPresenting else { return }
            guard let top = Self.topViewController() else { return }
            isPresenting = true

            let alert = UIAlertController(
                title: "",
                message: "로그인 세션이 만료되었습니다.\n다시 로그인해주세요.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { [weak self] _ in
                Task {
                    await TokenStorage.shared.clear()
                    await MainActor.run {
                        self?.switchToLogin()
                    }
                }
            }))
            top.present(alert, animated: true)
        }
    }

    @MainActor
    private func switchToLogin() {
        defer { isPresenting = false }
        let loginRoot = UINavigationController(rootViewController: LoginViewController())

        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive }),
              let delegate = scene.delegate as? SceneDelegate else {
            return
        }
        delegate.setRootViewController(loginRoot)
    }

    @MainActor
    private static func topViewController() -> UIViewController? {
        let root = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
        return resolveTop(from: root)
    }

    @MainActor
    private static func resolveTop(from root: UIViewController?) -> UIViewController? {
        guard let root else { return nil }
        if let presented = root.presentedViewController {
            return resolveTop(from: presented)
        }
        if let nav = root as? UINavigationController {
            return resolveTop(from: nav.visibleViewController)
        }
        if let tab = root as? UITabBarController {
            return resolveTop(from: tab.selectedViewController)
        }
        return root
    }
}
