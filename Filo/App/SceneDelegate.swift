//
//  SceneDelegate.swift
//  Filo
//
//  Created by 이상민 on 12/10/25.
//

import UIKit
import iamport_ios
import KakaoSDKAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    private var privacyCoverView: UIView?
    
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let uiWindowScene = (scene as? UIWindowScene) else { return }
        
        NavigationBarAppearance.configure()
        
        window = UIWindow(windowScene: uiWindowScene)
        window?.rootViewController = UIViewController()
        window?.makeKeyAndVisible()
        
        Task {
            let refreshToken = await TokenStorage.shared.refreshToken()
            if let refreshToken, !refreshToken.isEmpty {
                do {
                    _ = try await AuthService.shared.refreshAccessToken()
                    await MainActor.run {
                        self.setRootViewController(MainTabBarController())
                    }
                } catch {
                    await TokenStorage.shared.clear()
                    await MainActor.run {
                        self.setRootViewController(
                            UINavigationController(
                                rootViewController: MainTabBarController()
                            )
                        )
                    }
                }
            } else {
                await MainActor.run {
                    self.setRootViewController(UINavigationController(rootViewController: MainTabBarController()))
                }
            }
        }
    }
    
    func setRootViewController(_ viewController: UIViewController) {
        window?.rootViewController = viewController
        window?.makeKeyAndVisible()
        removePrivacyCover()
        AppLockCoordinator.shared.markNeedsUnlock()
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            AppLockCoordinator.shared.presentLockIfNeeded(in: self.window)
        }
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        AppLockCoordinator.shared.presentLockIfNeeded(in: window)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.removePrivacyCover()
        }
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
        AppLockCoordinator.shared.markNeedsUnlock()
        showPrivacyCoverIfNeeded()
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        showPrivacyCoverIfNeeded()
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url {
            Iamport.shared.receivedURL(url)
        }
        
        if let url = URLContexts.first?.url{
            if (AuthApi.isKakaoTalkLoginUrl(url)) {
                _ = AuthController.handleOpenUrl(url: url)
            }
        }
    }

    private func showPrivacyCoverIfNeeded() {
        guard ChatLockSettingsStore.shared.settings().isLockEnabled else { return }
        guard let window else { return }

        if let cover = privacyCoverView {
            window.bringSubviewToFront(cover)
            return
        }

        let cover = makePrivacyCoverView()
        cover.frame = window.bounds
        cover.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        window.addSubview(cover)
        window.bringSubviewToFront(cover)
        privacyCoverView = cover
    }

    private func removePrivacyCover() {
        privacyCoverView?.removeFromSuperview()
        privacyCoverView = nil
    }

    private func makePrivacyCoverView() -> UIView {
        let settings = ChatLockSettingsStore.shared.settings()
        let leadingAction: ChatLockLeadingAction = settings.isBiometricEnabled && ChatLockSettingsStore.shared.canUseBiometrics() ? .biometric : .empty
        let cover = ChatLockScreenView(
            title: "Filo 잠금",
            message: "Filo 암호를 입력해 주세요.",
            leadingAction: leadingAction,
            showsCloseButton: false,
            isInteractive: false
        )
        return cover
    }
}
