//
//  HomeViewModel.swift
//  Filo
//
//  Created by 이상민 on 1/21/26.
//

import Foundation
import RxSwift
import RxCocoa

final class HomeViewModel: ViewModelType{
    //MARK: - Properties
    private let disposeBag = DisposeBag()
    
    struct Input{
        
    }
    
    struct Output{
        let filterCategories: Driver<[FilterCategoryType]>
        let todayFilterData: Driver<TodayFilterResponseEntity>
        let hotTrendItems: Driver<[FilterSummaryResponseEntity]>
        let todayAuthorData: Driver<TodayAuthorResponseEntity>
        let bannerItems: Driver<BannerListResponseEntity>
    }
    
    func transform(input: Input) -> Output {
        let filterCategoriesRelay = BehaviorRelay<[FilterCategoryType]>(value: FilterCategoryType.allCases)
        let todayFilterRelay = PublishRelay<TodayFilterResponseEntity>()
        let hotTrendRelay = PublishRelay<[FilterSummaryResponseEntity]>()
        let todayAuthorRelay = PublishRelay<TodayAuthorResponseEntity>()
        let bannerRelay = PublishRelay<BannerListResponseEntity>()
        let networkErrorRelay = PublishRelay<NetworkError>()
        
        Task{
            do{
                let dto: TodayFilterResponseDTO = try await NetworkManager.shared.request(FilterRouter.todayFilter)
                
                todayFilterRelay.accept(dto.toEntity())
            }catch(let error as NetworkError){
                print(error)
                networkErrorRelay.accept(error)
            }
        }
        
        Task{
            do{
                let dto: BannerListResponseDTO = try await NetworkManager.shared.request(BannerRouter.main)
                
                bannerRelay.accept(dto.toEntity())
            }catch(let error as NetworkError){
                print(error)
                networkErrorRelay.accept(error)
            }
        }
        
        Task{
            do{
                let dto: FilterSummaryListResponseDTO = try await NetworkManager.shared.request(FilterRouter.hotTrend)
                
                hotTrendRelay.accept(dto.data.map{ $0.toEntity() })
            }catch(let error as NetworkError){
                print(error)
                networkErrorRelay.accept(error)
            }
        }
        
        Task{
            do{
                let dto: TodayAuthorResponseDTO = try await NetworkManager.shared.request(UserRouter.todayAuthor)
                
                todayAuthorRelay.accept(dto.toEntity())
            }catch(let error as NetworkError){
                print(error)
                networkErrorRelay.accept(error)
            }
        }
        
        return Output(
            filterCategories: filterCategoriesRelay.asDriver(),
            todayFilterData: todayFilterRelay.asDriver(onErrorDriveWith: .empty()),
            hotTrendItems: hotTrendRelay.asDriver(onErrorDriveWith: .empty()),
            todayAuthorData: todayAuthorRelay.asDriver(onErrorDriveWith: .empty()),
            bannerItems: bannerRelay.asDriver(onErrorDriveWith: .empty())
        )
    }
}
