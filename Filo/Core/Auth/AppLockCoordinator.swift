//
//  AppLockCoordinator.swift
//  Filo
//
//  Created by Codex on 3/12/26.
//

import UIKit

@MainActor
final class AppLockCoordinator {
    static let shared = AppLockCoordinator()

    private var requiresUnlock = true
    private var isPresentingLock = false
    private var retryCount = 0
    private let maxRetryCount = 10

    private init() { }

    func markNeedsUnlock() {
        requiresUnlock = true
        retryCount = 0
    }

    func presentLockIfNeeded(in window: UIWindow?) {
        guard requiresUnlock, !isPresentingLock else { return }
        guard ChatLockSettingsStore.shared.settings().isLockEnabled else { return }
        guard let window else { return }
        guard !isPlaceholderRoot(window.rootViewController) else {
            guard retryCount < maxRetryCount else { return }
            retryCount += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.presentLockIfNeeded(in: window)
            }
            return
        }
        guard let presenter = topViewController(from: window.rootViewController) else { return }
        guard !(presenter is ChatLockEntryViewController) else { return }
        guard presenter.viewIfLoaded?.window != nil else {
            guard retryCount < maxRetryCount else { return }
            retryCount += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.presentLockIfNeeded(in: window)
            }
            return
        }

        isPresentingLock = true
        retryCount = 0

        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { isPresentingLock = false }

            do {
                try await DeviceSecurityAuthenticator.shared.authenticateForAppAccess(from: presenter)
                requiresUnlock = false
            } catch let error as DeviceSecurityAuthError where error == .canceled {
                return
            } catch {
                requiresUnlock = true
            }
        }
    }

    private func topViewController(from root: UIViewController?) -> UIViewController? {
        if let nav = root as? UINavigationController {
            return topViewController(from: nav.visibleViewController)
        }
        if let tab = root as? UITabBarController {
            return topViewController(from: tab.selectedViewController)
        }
        if let presented = root?.presentedViewController {
            return topViewController(from: presented)
        }
        return root
    }

    private func isPlaceholderRoot(_ root: UIViewController?) -> Bool {
        guard let root else { return true }
        if root is MainTabBarController {
            return false
        }
        if let nav = root as? UINavigationController {
            guard let first = nav.viewControllers.first else { return true }
            return type(of: first) == UIViewController.self
        }
        return type(of: root) == UIViewController.self
    }
}
