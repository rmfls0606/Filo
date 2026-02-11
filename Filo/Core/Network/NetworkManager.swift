//
//  NetworkManager.swift
//  Filo
//
//  Created by 이상민 on 1/20/26.
//

import Foundation
import Alamofire

protocol NetworkManagerProtocol{
    func request<T: Decodable>(_ router: APITarget) async throws -> T
    func upload<T: Decodable>(_ router: APITarget, files: [MultipartFile]) async throws -> T
    func requestEmpty(_ router: APITarget) async throws
}

final class NetworkManager: NetworkManagerProtocol{
    static let shared = NetworkManager()
    
    private init(){ }
    
    private let maxRetryCount = 2
    private let uploadSession: Session = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 180
        config.timeoutIntervalForResource = 300
        return Session(configuration: config)
    }()
    
    func request<T: Decodable>(_ router: APITarget) async throws -> T{
        try await execute(router: router,
                          retryCount: 0){
            try await self.sendRequest(router: router, type: T.self)
        }
    }

    func upload<T: Decodable>(_ router: APITarget, files: [MultipartFile]) async throws -> T {
        try await execute(router: router, retryCount: 0){
            try await self.sendUpload(router: router, files: files, type: T.self)
        }
           
    }

    func requestEmpty(_ router: APITarget) async throws {
        try await executeVoid(router: router, retryCount: 0) {
            try await self.sendEmptyRequest(router: router)
        }
    }
}

private extension NetworkManager{
    func executeVoid(router: APITarget, retryCount: Int, action: @escaping () async throws -> Void) async throws {
        do {
            return try await action()
        } catch let error as NetworkError {
            if case .statusCodeError(let type) = error, type == .refreshTokenExpired {
                await SessionExpiryHandler.shared.handleSessionExpired()
                throw error
            }
            guard retryCount < maxRetryCount else { throw error }

            if case .statusCodeError(let type) = error,
               type == .accessTokenExpired || type == .unauthorized {
                guard let auth = router.headers["Authorization"], !auth.isEmpty else {
                    throw error
                }
                guard !router.path.contains("/auth/refresh") else { throw error }
                do {
                    _ = try await TokenStorage.shared.refreshUpdate({
                        try await AuthService.shared.refreshAccessToken()
                    })
                    return try await executeVoid(router: router, retryCount: retryCount + 1, action: action)
                } catch {
                    await SessionExpiryHandler.shared.handleSessionExpired()
                    throw NetworkError.statusCodeError(type: .refreshTokenExpired)
                }
            }

            throw error
        }
    }

    func execute<T: Decodable>(router: APITarget, retryCount: Int, action: @escaping () async throws -> T) async throws -> T{
        do{
            return try await action()
        }catch let error as NetworkError{
            if case .statusCodeError(let type) = error, type == .refreshTokenExpired {
                await SessionExpiryHandler.shared.handleSessionExpired()
                throw error
            }
            //retry초과
            guard retryCount < maxRetryCount else{
                throw error
            }
            
            //accessToken 만료 / 인증 실패
            if case .statusCodeError(let type) = error,
               type == .accessTokenExpired || type == .unauthorized{
                guard let auth = router.headers["Authorization"], !auth.isEmpty else {
                    throw error
                }
                
                //refresh 요청은 재시도 금지
                guard !router.path.contains("/auth/refresh") else{
                    throw error
                }
                
                do{
                    _ = try await TokenStorage.shared.refreshUpdate({
                        try await AuthService.shared.refreshAccessToken()
                    })
                    
                    //retry
                    return try await execute(router: router, retryCount: retryCount + 1, action: action)
                }catch{
                    await SessionExpiryHandler.shared.handleSessionExpired()
                    throw NetworkError.statusCodeError(type: .refreshTokenExpired)
                }
            }
            
            throw error
        }
    }
}

private extension NetworkManager{
    func sendEmptyRequest(router: APITarget) async throws {
        let response = await AF.request(router.endPoint,
                                        method: router.method,
                                        parameters: router.parameters,
                                        encoding: router.encoding,
                                        headers: router.headers)
            .validate(statusCode: 200..<300)
            .serializingData(emptyResponseCodes: [200, 204])
            .response

        switch response.result{
        case .success:
            return
        case .failure(let error):
            print(error)
            throw NetworkError.mapping(error: error,
                                       statusCode: response.response?.statusCode,
                                       data: response.data)
        }
    }

    func sendRequest<T: Decodable>(router: APITarget, type: T.Type) async throws -> T{
        let response = await AF.request(router.endPoint,
                                        method: router.method,
                                        parameters: router.parameters,
                                        encoding: router.encoding,
                                        headers: router.headers)
            .validate(statusCode: 200..<300)
            .serializingDecodable(T.self)
            .response
        
        switch response.result{
        case .success(let value):
            return value
        case .failure(let error):
            print(error)
            throw NetworkError.mapping(error: error,
                                       statusCode: response.response?.statusCode,
                                       data: response.data)
        }
    }
}

private extension NetworkManager{
    func sendUpload<T: Decodable>(router: APITarget, files: [MultipartFile], type: T.Type) async throws -> T{
        let response = await uploadSession.upload(multipartFormData: { form in
            files.forEach { file in
                form.append(file.data,
                            withName: file.name,
                            fileName: file.fileName,
                            mimeType: file.mimeType)
        }}, to: router.endPoint, method: router.method, headers: router.headers)
            .validate(statusCode: 200..<300)
            .serializingDecodable(T.self)
            .response
        
        switch response.result{
        case . success(let value):
            return value
        case .failure(let error):
            print(error)
            throw NetworkError.mapping(error: error,
                                       statusCode: response.response?.statusCode,
                                       data: response.data)
        }
    }
}
