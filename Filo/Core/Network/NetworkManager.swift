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
}

final class NetworkManager: NetworkManagerProtocol{
    static let shared = NetworkManager()
    
    private init(){ }
    
    func request<T: Decodable>(_ router: APITarget) async throws -> T{
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
            throw NetworkError.mapping(error: error, statusCode: response.response?.statusCode, data: response.data)
        }
    }
}
