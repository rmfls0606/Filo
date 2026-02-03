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
        let selectedHotTrendItem: ControlEvent<FilterSummaryResponseEntity>
    }
    
    struct Output{
        let filterCategories: Driver<[FilterCategoryType]>
        let todayFilterData: Driver<TodayFilterResponseEntity>
        let hotTrendItems: Driver<[FilterSummaryResponseEntity]>
        let todayAuthorData: Driver<TodayAuthorResponseEntity>
        let bannerItems: Driver<BannerListResponseEntity>
        let hotTrendItem: Driver<String>
        let networkError: Signal<NetworkError>
    }
    
    func transform(input: Input) -> Output {
        let filterCategoriesRelay = BehaviorRelay<[FilterCategoryType]>(value: FilterCategoryType.allCases)
        let todayFilterRelay = PublishRelay<TodayFilterResponseEntity>()
        let hotTrendRelay = PublishRelay<[FilterSummaryResponseEntity]>()
        let todayAuthorRelay = PublishRelay<TodayAuthorResponseEntity>()
        let bannerRelay = PublishRelay<BannerListResponseEntity>()
        let networkErrorRelay = PublishRelay<NetworkError>()
        let selectedHotTrendItemRelay = PublishRelay<String>()
        
        Task{
            do{
                let dto: TodayFilterResponseDTO = try await NetworkManager.shared.request(FilterRouter.todayFilter)
                
                todayFilterRelay.accept(dto.toEntity())
            }catch(let error as NetworkError){
                networkErrorRelay.accept(error)
            }catch(let error){
                networkErrorRelay.accept(NetworkError.unknown(error))
            }
        }
        
        Task{
            do{
                let dto: BannerListResponseDTO = try await NetworkManager.shared.request(BannerRouter.main)
                
                bannerRelay.accept(dto.toEntity())
            }catch(let error as NetworkError){
                networkErrorRelay.accept(error)
            }catch(let error){
                networkErrorRelay.accept(NetworkError.unknown(error))
            }
        }
        
        Task{
            do{
                let dto: FilterSummaryListResponseDTO = try await NetworkManager.shared.request(FilterRouter.hotTrend)
                let entities = dto.data.map { $0.toEntity() }
                entities.forEach { item in
                    LikeStore.shared.setLiked(id: item.filterId, liked: item.isLiked, count: item.likeCount)
                }
                hotTrendRelay.accept(entities)
            }catch(let error as NetworkError){
                networkErrorRelay.accept(error)
            }catch(let error){
                networkErrorRelay.accept(NetworkError.unknown(error))
            }
        }
        
        Task{
            do{
                let dto: TodayAuthorResponseDTO = try await NetworkManager.shared.request(UserRouter.todayAuthor)
                
                todayAuthorRelay.accept(dto.toEntity())
            }catch(let error as NetworkError){
                networkErrorRelay.accept(error)
            }catch(let error){
                networkErrorRelay.accept(NetworkError.unknown(error))
            }
        }
        
        input.selectedHotTrendItem
            .map{ $0.filterId }
            .bind(to: selectedHotTrendItemRelay)
            .disposed(by: disposeBag)
        
        return Output(
            filterCategories: filterCategoriesRelay.asDriver(),
            todayFilterData: todayFilterRelay.asDriver(onErrorDriveWith: .empty()),
            hotTrendItems: hotTrendRelay.asDriver(onErrorDriveWith: .empty()),
            todayAuthorData: todayAuthorRelay.asDriver(onErrorDriveWith: .empty()),
            bannerItems: bannerRelay.asDriver(onErrorDriveWith: .empty()),
            hotTrendItem: selectedHotTrendItemRelay.asDriver(onErrorDriveWith: .empty()),
            networkError: networkErrorRelay.asSignal()
        )
    }
}
