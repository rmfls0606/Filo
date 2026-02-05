//
//  BannerWebViewModel.swift
//  Filo
//
//  Created by 이상민 on 2/5/26.
//

import Foundation
import RxSwift
import RxCocoa

final class BannerWebViewModel: ViewModelType{
    private let banner: BannerDTO
    
    init(banner: BannerDTO) {
        self.banner = banner
    }
    
    private let disposeBag = DisposeBag()
    
    struct Input{ }
    
    struct Output{
        let bannerData: Driver<BannerDTO>
        let validAccessToken: Signal<String>
    }
    
    func transform(input: Input) -> Output {
        let bannerDataRelay = BehaviorRelay<BannerDTO>(value: banner)
        let validAccessTokenRelay = PublishRelay<String>()
        
        Task{
            do{
                let token = try await Self.validAccessToken()
                validAccessTokenRelay.accept(token)
            }catch{
                validAccessTokenRelay.accept("")
            }
        }
        
        return Output(
            bannerData: bannerDataRelay.asDriver(),
            validAccessToken: validAccessTokenRelay.asSignal()
        )
    }

    static func validAccessToken() async throws -> String {
        if let token = await TokenStorage.shared.accessToken(),
           !token.isEmpty {
            return token
        }
        _ = try await TokenStorage.shared.refreshUpdate {
            try await AuthService.shared.refreshAccessToken()
        }
        if let refreshed = await TokenStorage.shared.accessToken(),
           !refreshed.isEmpty {
            return refreshed
        }
        throw NetworkError.statusCodeError(type: .refreshTokenExpired)
    }
}
