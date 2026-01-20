//
//  NetworkError.swift
//  Filo
//
//  Created by 이상민 on 1/20/26.
//

import Foundation

enum NetworkError: LocalizedError{
    case invalidURL //URL 생성 실패
    case serverError(ServerErrorDTO) //서버에서 내려준 구체적인 에러 메시지
    case notConnectedToInternet //인터넷 연결 없음
    case timeOut //요청 시간 초과
    case noResponse //네트워크 응답 없음
    case decodingError //JSON 디코딩 실패
    case statusCodeError(type: StatusCodeError) //HTTP 상태 코드 에러(400, 401, 418 등)
    case unknown(Error) //그 외
    
    var errorDescription: String?{
        switch self {
        case .invalidURL:
            return "잘못된 요청입니다."
        case .serverError(let data):
            return data.message
        case .notConnectedToInternet:
            return "네트워크 연결이 원활하지 않습니다.\nWi-Fi 또는 데이터 상태를 확인해주세요."
        case .timeOut:
            return "요청 시간이 초과되었습니다."
        case .noResponse:
            return "유효하지 않은 서버 응답입니다."
        case .decodingError:
            return "데이터 처리에 실패했습니다."
        case .statusCodeError(let type):
            return type.errorDescription
        case .unknown(let error):
            return "알 수 없는 오류가 발생했습니다.\(error.localizedDescription)"
        }
    }
}

extension NetworkError{
    static func mapping(error: Error?, response: URLResponse?, data: Data?) throws(NetworkError){
        
        if let data,
           let result = try? JSONDecoder().decode(ServerErrorDTO.self, from: data){
            throw .serverError(result)
        }
        
        if let httpResponse = response as? HTTPURLResponse{
            if !(200..<300).contains(httpResponse.statusCode){
                throw .statusCodeError(type: StatusCodeError.codeMapping(statusCode: httpResponse.statusCode))
            }
        }
        
        if let urlError = error as? URLError{
            switch urlError.code{
            case .notConnectedToInternet:
                throw .notConnectedToInternet
            case .timedOut:
                throw .timeOut
            default:
                throw .unknown(urlError)
            }
        }
    }
}

enum StatusCodeError: LocalizedError{
    case badRequest //400
    case unauthorized //401 - 유효하지 않은 accessToken일 경우
    case forbidden //403 - user_id 조회를 할 수 없는 경우
    case notFound //404
    case refreshTokenExpired //418 - refreshToken이 만료된 경우
    case accessTokenExpired //419 - accessToken이 만료된 경우
    case serverError
    case other(code: Int) //그 외
    
    var errorDescription: String?{
        switch self {
        case .badRequest:
            return "잘못된 요청입니다."
        case .unauthorized:
            return "인증에 실패했습니다."
        case .forbidden:
            return "접근 권한이 없습니다."
        case .refreshTokenExpired:
            return "로그인 세션이 만료되었습니다. 다시 로그인 해주세요."
        case .accessTokenExpired:
            return "접근 권한이 만료되었습니다."
        case .notFound:
            return "요청한 정보를 찾을 수 없습니다."
        case .serverError:
            return "서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요."
        case .other(let code):
            return "오류가 발생했습니다. (코드: \(code))"
        }
    }
}

extension StatusCodeError{
    static func codeMapping(statusCode: Int) -> StatusCodeError {
        switch statusCode{
        case 400: return .badRequest
        case 401: return .unauthorized
        case 403: return .forbidden
        case 404: return .notFound
        case 418: return .refreshTokenExpired
        case 419: return .accessTokenExpired
        case 500...599: return .serverError
        default: return .other(code: statusCode)
        }
    }
}
