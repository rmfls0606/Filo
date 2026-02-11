//
//  AppDelegate.swift
//  Filo
//
//  Created by 이상민 on 12/10/25.
//

import UIKit
import FirebaseCore
import FirebaseMessaging
import IQKeyboardManagerSwift
import Kingfisher
import KakaoSDKCommon

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    private var pendingPushRoomId: String?
    private var pendingNavigationWorkItem: DispatchWorkItem?
    private let maxPendingNavigationRetry = 25

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        
        if #available(iOS 10.0, *){
            UNUserNotificationCenter.current().delegate = self

            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
              options: authOptions,
              completionHandler: { _, _ in }
            )
        }else{
            let settings: UIUserNotificationSettings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        KakaoSDK.initSDK(appKey: NetworkConfig.nativeKey)
        
        application.registerForRemoteNotifications()
        
        Messaging.messaging().delegate = self
        
        Messaging.messaging().token { token, error in
          if let error = error {
            print("Error fetching FCM registration token: \(error)")
          } else if let token = token {
              print("register: toke", token)
          }
        }

        IQKeyboardManager.shared.isEnabled = true

        let cache = ImageCache.default
        cache.memoryStorage.config.totalCostLimit = 120 * 1024 * 1024
        cache.diskStorage.config.sizeLimit = 500 * 1024 * 1024
        cache.memoryStorage.config.expiration = .seconds(60 * 60)
        cache.diskStorage.config.expiration = .days(30)
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate{
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
}

extension AppDelegate: MessagingDelegate{
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {

      let dataDict: [String: String] = ["token": fcmToken ?? ""]
      NotificationCenter.default.post(
        name: Notification.Name("FCMToken"),
        object: nil,
        userInfo: dataDict
      )

      guard let token = fcmToken, !token.isEmpty else { return }
      let previous = UserDefaults.standard.string(forKey: "fcmToken")
      guard previous != token else { return }
      UserDefaults.standard.set(token, forKey: "fcmToken")
      Task {
          if let _ = await TokenStorage.shared.accessToken() {
              do {
                  try await NetworkManager.shared.requestEmpty(
                      UserRouter.deviceToken(deviceToken: token)
                  )
                  debugPrint("Device token updated: \(token)")
              } catch {
                  debugPrint("Device token update failed: \(error)")
              }
          }
      }
    }
}

extension AppDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let top = topViewController()
        let roomId = extractRoomId(from: notification.request.content.userInfo)

        if let roomId, shouldIncrementUnread(top: top, roomId: roomId) {
            ChatLocalStore.shared.incrementUnread(roomId: roomId)
        }

        if top is ChatRoomListViewController {
            completionHandler([])
            return
        }
        if top is ChatRoomViewController,
           (roomId == nil || roomId == CurrentChatRoom.shared.roomId) {
            completionHandler([])
        } else {
            completionHandler([.banner, .sound, .badge])
        }
    }
}

extension AppDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        if let roomId = extractRoomId(from: response.notification.request.content.userInfo) {
            DispatchQueue.main.async { [weak self] in
                self?.enqueueOpenChatRoom(roomId: roomId)
            }
        }
        completionHandler()
    }
}

private extension AppDelegate {
    func topViewController() -> UIViewController? {
        let root = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
        return topViewController(from: root)
    }

    func topViewController(from root: UIViewController?) -> UIViewController? {
        guard let root else { return nil }
        if let presented = root.presentedViewController {
            return topViewController(from: presented)
        }
        if let nav = root as? UINavigationController {
            return topViewController(from: nav.visibleViewController)
        }
        if let tab = root as? UITabBarController {
            return topViewController(from: tab.selectedViewController)
        }
        return root
    }

    func extractRoomId(from userInfo: [AnyHashable: Any]) -> String? {
        if let roomId = userInfo["room_id"] as? String, !roomId.isEmpty {
            return roomId
        }
        if let roomId = userInfo["room_id"] as? NSNumber {
            return roomId.stringValue
        }
        return nil
    }

    func shouldIncrementUnread(top: UIViewController?, roomId: String) -> Bool {
        if top is ChatRoomListViewController {
            return false
        }
        if top is ChatRoomViewController,
           CurrentChatRoom.shared.roomId == roomId {
            return false
        }
        return true
    }

    func openChatRoom(roomId: String) {
        let currentUserId = (try? KeychainManager.shared.read(key: .userId)) ?? ""

        let listVM = ChatRoomListViewModel(currentUserId: currentUserId)
        let listVC = ChatRoomListViewController(viewModel: listVM)
        let roomVM = ChatRoomViewModel(roomId: roomId, opponentId: nil)
        let roomVC = ChatRoomViewController(viewModel: roomVM)

        if let tab = mainTabBarController() {
            tab.setSelectedIndex(TabBarItem.profile.rawValue)
            if let nav = tab.viewControllers?[4] as? UINavigationController,
               let profileVC = nav.viewControllers.first {
                nav.setViewControllers([profileVC, listVC, roomVC], animated: true)
                return
            }
        }

        let top = topViewController()
        let navController = (top as? UINavigationController) ?? top?.navigationController
        if let navController {
            navController.setViewControllers([listVC, roomVC], animated: true)
        } else if let top {
            let nav = UINavigationController(rootViewController: listVC)
            nav.pushViewController(roomVC, animated: false)
            top.present(nav, animated: true)
        }
    }

    func enqueueOpenChatRoom(roomId: String) {
        pendingPushRoomId = roomId
        pendingNavigationWorkItem?.cancel()
        tryOpenPendingChatRoom(retryCount: 0)
    }

    func tryOpenPendingChatRoom(retryCount: Int) {
        guard let roomId = pendingPushRoomId else { return }

        if let tab = mainTabBarController() {
            tab.setSelectedIndex(TabBarItem.profile.rawValue)
            pendingPushRoomId = nil
            openChatRoom(roomId: roomId)
            return
        }

        guard retryCount < maxPendingNavigationRetry else {
            pendingPushRoomId = nil
            return
        }

        let workItem = DispatchWorkItem { [weak self] in
            self?.tryOpenPendingChatRoom(retryCount: retryCount + 1)
        }
        pendingNavigationWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: workItem)
    }

    func mainTabBarController() -> MainTabBarController? {
        let root = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
        if let tab = root as? MainTabBarController {
            return tab
        }
        if let nav = root as? UINavigationController,
           let tab = nav.viewControllers.first as? MainTabBarController {
            return tab
        }
        return nil
    }
}
