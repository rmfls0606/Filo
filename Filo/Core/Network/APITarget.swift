//
//  APITarget.swift
//  Filo
//
//  Created by 이상민 on 1/20/26.
//

import Alamofire

protocol APITarget{
    var baseURL: String { get }
    var path: String { get }
    var endPoint: String { get }
    var method: HTTPMethod { get }
    var headers: HTTPHeaders { get }
    var parameters: Parameters? { get }
    var encoding: ParameterEncoding { get }
}

extension APITarget{
    var baseURL: String{
        return NetworkConfig.baseURL
    }
    
    var endPoint: String{
        return baseURL + path
    }
}
