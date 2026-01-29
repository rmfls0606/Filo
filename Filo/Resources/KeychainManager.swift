//
//  KeychainManager.swift
//  Filo
//
//  Created by 이상민 on 1/21/26.
//

import Foundation
import Security

enum KeychainError: Error{
    case encodingFailed
    case decodingFailed
    case itemNotFound
    case unexpectedStatus(OSStatus)
}

final class KeychainManager{
    static let shared = KeychainManager()
    
    private init(){ }
    
    private let service = Bundle.main.bundleIdentifier ?? "DefaultService"
    
    enum Key: String, CaseIterable{
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case userId = "user_id"
    }
    
    //MARK: - Save
    func save(_ value: String, key: Key) throws{
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue
        ]
        
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        
        if status == errSecSuccess { return }
        
        if status == errSecItemNotFound{
            var newItem = query
            newItem.merge(attributes) { $1 }
            
            let addStatus = SecItemAdd(newItem as CFDictionary, nil)
            if addStatus != errSecSuccess{
                throw KeychainError.unexpectedStatus(addStatus)
            }
        }else{
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    //MARK: - Read
    func read(key: Key) throws -> String{
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataRef)
        
        if status == errSecItemNotFound{
            throw KeychainError.itemNotFound
        }
        
        guard status == errSecSuccess else{
            throw KeychainError.unexpectedStatus(status)
        }
        
        guard let data = dataRef as? Data,
              let value = String(data: data, encoding: .utf8) else{
            throw KeychainError.decodingFailed
        }
        
        return value
    }
    
    //MARK: - Delete
    func delete(key: Key){
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    //MARK: - Clear
    func clearAll(){
        Key.allCases.forEach{ delete(key: $0) }
    }
}
