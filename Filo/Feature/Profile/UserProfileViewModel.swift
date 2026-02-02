//
//  UserProfileViewModel.swift
//  Filo
//
//  Created by 이상민 on 2/2/26.
//

import Foundation
import RxSwift
import RxCocoa

final class UserProfileViewModel: ViewModelType{
    
    private let userId: String
    
    init(userId: String){
        self.userId = userId
    }
    
    struct Input{
        
    }
    
    struct Output{
        let profileItem: Driver<UserInfoResponseDTO?>
    }
    
    func transform(input: Input) -> Output {
        let networkErrorRelay = PublishRelay<NetworkError>()
        let otherProfileDataRelay = BehaviorRelay<UserInfoResponseDTO?>(value: nil)
        
        Task{
            do{
                let dto: UserInfoResponseDTO = try await NetworkManager.shared.request(UserRouter.otherProfile(userId: userId))
                otherProfileDataRelay.accept(dto)
            }catch let error as NetworkError{
                print(error)
                networkErrorRelay.accept(error)
            }
        }
        
        
        return Output(
            profileItem: otherProfileDataRelay.asDriver()
        )
    }
}
