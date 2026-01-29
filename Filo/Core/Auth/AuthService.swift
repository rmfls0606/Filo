//
//  AuthService.swift
//  Filo
//
//  Created by 이상민 on 1/22/26.
//

import Foundation

final class AuthService{
    static let shared = AuthService()
    
    private init(){ }
    
    func refreshAccessToken() async throws -> String{
        guard let refreshToken = await TokenStorage.shared.refreshToken(),
              !refreshToken.isEmpty else{
            throw NetworkError.statusCodeError(type: .refreshTokenExpired)
        }
        
        let response: RefreshTokenResponseDTO = try await NetworkManager.shared.request(UserRouter.auth(refresh: refreshToken))
        
        try await TokenStorage.shared.save(access: response.accessToken, refresh: response.refreshToken
        )
        
        return response.accessToken
    }
}

