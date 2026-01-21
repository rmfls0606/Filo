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
    }
    
    func transform(input: Input) -> Output {
        let filterCategoriesRelay = BehaviorRelay<[FilterCategoryType]>(value: FilterCategoryType.allCases)
        let todayFilterRelay = PublishRelay<TodayFilterResponseEntity>()
        let hotTrendRelay = PublishRelay<[FilterSummaryResponseEntity]>()
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
                let dto: FilterSummaryListResponseDTO = try await NetworkManager.shared.request(FilterRouter.hotTrend)
                
                hotTrendRelay.accept(dto.data.map{ $0.toEntity() })
            }catch(let error as NetworkError){
                print(error)
                networkErrorRelay.accept(error)
            }
        }
        
        return Output(
            filterCategories: filterCategoriesRelay.asDriver(),
            todayFilterData: todayFilterRelay.asDriver(onErrorDriveWith: .empty()),
            hotTrendItems: hotTrendRelay.asDriver(onErrorDriveWith: .empty())
        )
    }
}
