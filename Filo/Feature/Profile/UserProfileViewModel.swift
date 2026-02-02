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
    private let disposeBag = DisposeBag()
    private let userId: String
    
    init(userId: String){
        self.userId = userId
    }
    
    struct Input{
        let selectedSegment: Observable<Int>
    }
    
    struct Output{
        let profileItem: Driver<UserInfoResponseDTO?>
        let userFilterItems: Driver<[FilterSummaryResponseDTO]>
        let userCommunityItems: Driver<[PostSummaryResponseDTO]>
        let selectedSegment: Driver<Int>
    }
    
    func transform(input: Input) -> Output {
        let networkErrorRelay = PublishRelay<NetworkError>()
        let otherProfileDataRelay = BehaviorRelay<UserInfoResponseDTO?>(value: nil)
        let userFilterItemsRelay = BehaviorRelay<[FilterSummaryResponseDTO]>(value: [])
        let userCommunityItemsRelay = BehaviorRelay<[PostSummaryResponseDTO]>(value: [])
        let selectedSegmentRelay = BehaviorRelay<Int>(value: 0)
        
        Task{
            do{
                let dto: UserInfoResponseDTO = try await NetworkManager.shared.request(UserRouter.otherProfile(userId: userId))
                otherProfileDataRelay.accept(dto)
            }catch let error as NetworkError{
                print(error)
                networkErrorRelay.accept(error)
            }
        }

        Task{
            do{
                let dto: FilterSummaryPaginationListResponseDTO = try await NetworkManager.shared.request(
                    FilterRouter.user(userId: userId, next: "", limit: "30", category: "")
                )
                userFilterItemsRelay.accept(dto.data)
            }catch let error as NetworkError{
                print(error)
                networkErrorRelay.accept(error)
            }
        }
        
        Task{
            do{
                let dto: PostSummaryPaginationResponseDTO = try await NetworkManager.shared.request(CommunityRouter.user(category: "", limit: "", next: "", userId: userId))
                userCommunityItemsRelay.accept(dto.data)
            }catch let error as NetworkError{
                print(error)
                networkErrorRelay.accept(error)
            }
        }
        
        input.selectedSegment
            .distinctUntilChanged()
            .bind(to:selectedSegmentRelay)
            .disposed(by: disposeBag)
        
        return Output(
            profileItem: otherProfileDataRelay.asDriver(),
            userFilterItems: userFilterItemsRelay.asDriver(),
            userCommunityItems: userCommunityItemsRelay.asDriver(),
            selectedSegment: selectedSegmentRelay.asDriver()
        )
    }
}
