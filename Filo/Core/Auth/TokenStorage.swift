//
//  TokenStorage.swift
//  Filo
//
//  Created by 이상민 on 1/21/26.
//

import Foundation

//토큰 저장 + refresh 동시성 제어만
final actor TokenStorage{
    static let shared = TokenStorage()

    private var refreshTask: Task<String, Error>?
    
    private init(){ }
    
    //MARK: - Read
    func accessToken() async -> String?{
        try? await KeychainManager.shared.read(key: .accessToken)
    }
    
    func refreshToken() async -> String?{
        try? await KeychainManager.shared.read(key: .refreshToken)
    }
    
    //MARK: - Save
    func save(access: String, refresh: String, userId: String? = nil) async throws{
        try await KeychainManager.shared.save(access, key: .accessToken)
        try await KeychainManager.shared.save(refresh, key: .refreshToken)
        if let userId {
            try await KeychainManager.shared.save(userId, key: .userId)
        }
    }
    
    //MARK: - Clear
    func clear() async{
        await KeychainManager.shared.clearAll()
    }
    
    //MARK: - Refresh 단일화
    func refreshUpdate(_ refreshBlock: @escaping () async throws -> String) async throws -> String{
        if let task = refreshTask{
            return try await task.value
        }
        
        let task = Task{
            defer{ refreshTask = nil }
            return try await refreshBlock()
        }
        
        refreshTask = task
        return try await task.value
    }
}
