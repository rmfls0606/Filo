//
//  ChatLockSettingsStore.swift
//  Filo
//
//  Created by Codex on 3/12/26.
//

import Foundation
import CryptoKit
import Security
import LocalAuthentication

struct ChatLockSettings {
    let isLockEnabled: Bool
    let isBiometricEnabled: Bool
    let hasPasscode: Bool
}

final class ChatLockSettingsStore {
    static let shared = ChatLockSettingsStore()

    private let defaults = UserDefaults.standard
    private let service = (Bundle.main.bundleIdentifier ?? "Filo") + ".chat-lock"
    private let passcodeAccount = "chat_lock_passcode_hash"
    private let lockEnabledKey = "chat_lock_enabled"
    private let biometricEnabledKey = "chat_lock_biometric_enabled"

    private init() { }

    func settings() -> ChatLockSettings {
        ChatLockSettings(
            isLockEnabled: defaults.bool(forKey: lockEnabledKey),
            isBiometricEnabled: defaults.bool(forKey: biometricEnabledKey),
            hasPasscode: (try? readPasscodeHash())?.isEmpty == false
        )
    }

    func setLockEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: lockEnabledKey)
        if !enabled {
            defaults.set(false, forKey: biometricEnabledKey)
        }
    }

    func setBiometricEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: biometricEnabledKey)
    }

    func updatePasscode(_ passcode: String) throws {
        try savePasscodeHash(Self.hash(passcode))
    }

    func verifyPasscode(_ passcode: String) -> Bool {
        guard let stored = try? readPasscodeHash() else { return false }
        return stored == Self.hash(passcode)
    }

    func canUseBiometrics() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    private func savePasscodeHash(_ hash: String) throws {
        guard let data = hash.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: passcodeAccount
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecSuccess { return }

        if status == errSecItemNotFound {
            var item = query
            item.merge(attributes) { $1 }
            let addStatus = SecItemAdd(item as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainError.unexpectedStatus(addStatus)
            }
            return
        }

        throw KeychainError.unexpectedStatus(status)
    }

    private func readPasscodeHash() throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: passcodeAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataRef)
        if status == errSecItemNotFound {
            throw KeychainError.itemNotFound
        }
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
        guard let data = dataRef as? Data,
              let value = String(data: data, encoding: .utf8) else {
            throw KeychainError.decodingFailed
        }
        return value
    }

    private static func hash(_ passcode: String) -> String {
        let digest = SHA256.hash(data: Data(passcode.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
