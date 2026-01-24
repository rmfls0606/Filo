//
//  FeedViewModel.swift
//  Filo
//
//  Created by 이상민 on 1/23/26.
//

import Foundation
import RxSwift
import RxCocoa

final class FeedViewModel: ViewModelType {
    let category: String
    private let disposeBag = DisposeBag()
    
    init(category: String = ""){
        self.category = category
    }
    
    struct Input{
        let orderByItemSelected: Observable<OrderByItem>
        let feedFilterModeSelected: ControlEvent<Void>
        let likeTapped: Observable<LikeInputTap>
    }
    
    struct Output{
        let selectedOrder: Driver<OrderByItem>
        let filtersData: Driver<FilterSummaryPaginationListResponseEntity>
        let feedFilterMode: Driver<Bool>
        let likeUIUpdate: Driver<OutputLikeUpdate>
    }
    
    func transform(input: Input) -> Output {
        let selectedOrderRelay = BehaviorRelay<OrderByItem>(value: .popularity)
        let filtersDataRelay = PublishRelay<FilterSummaryPaginationListResponseEntity>()
        let networkErrorRelay = PublishRelay<NetworkError>()
        let categoryRelay = BehaviorRelay<String>(value: category)
        let feedFileterModeRelay = BehaviorRelay<Bool>(value: true) //true: listMode, false: blockMode
        let likeUIUpdateRelay = PublishRelay<OutputLikeUpdate>()
        
        input.orderByItemSelected
            .bind(to: selectedOrderRelay)
            .disposed(by: disposeBag)
        
        Observable
            .combineLatest(categoryRelay, selectedOrderRelay){ category, selected in
                return (category: category, selected: selected)
            }
            .distinctUntilChanged{ $0.selected == $1.selected}
            .subscribe(onNext: { parm in
                Task{
                    do{
                        let dto: FilterSummaryPaginationListResponseDTO = try await NetworkManager.shared.request(FilterRouter.filters(next: "", limit: "", category: parm.category, orderBy: parm.selected.orderByName))
                        let entity = dto.toEntity()
                        entity.data.forEach { item in
                            LikeStore.shared.setLiked(id: item.filterId, liked: item.isLiked, count: item.likeCount)
                        }
                        filtersDataRelay.accept(entity)
                    }catch(let error as NetworkError){
                        print(error)
                        networkErrorRelay.accept(error)
                    }
                }
            })
            .disposed(by: disposeBag)
        
        input.likeTapped
            .subscribe(onNext: { payload in
                let currentLiked = LikeStore.shared.isLiked(id: payload.item.filterId)
                let desiredLiked = !currentLiked
                
                Task{
                    do{
                        let dto: PostLikeResponseDTO = try await NetworkManager.shared.request(
                            FilterRouter.like(filterId: payload.item.filterId, liked: desiredLiked)
                        )
                        let entity = dto.toEntity()
                        let likedNow = entity.likeStatus
                        let baseCount = LikeStore.shared.likeCount(id: payload.item.filterId) ?? payload.item.likeCount
                        let delta = likedNow ? 1 : -1
                        let likeCount = max(0, baseCount + delta)
                        LikeStore.shared.setLiked(id: payload.item.filterId, liked: likedNow, count: likeCount)
                        likeUIUpdateRelay.accept(OutputLikeUpdate(
                            filterId: payload.item.filterId,
                            index: payload.index,
                            liked: likedNow
                        ))
                    }catch(let error as NetworkError){
                        print(error)
                        networkErrorRelay.accept(error)
                    }
                }
            })
            .disposed(by: disposeBag)
        
        input.feedFilterModeSelected
            .withLatestFrom(feedFileterModeRelay)
            .map{ !$0}
            .bind(to: feedFileterModeRelay)
            .disposed(by: disposeBag)
        
        return Output(
            selectedOrder: selectedOrderRelay.asDriver(),
            filtersData: filtersDataRelay.asDriver(onErrorDriveWith: .empty()),
            feedFilterMode: feedFileterModeRelay.asDriver(),
            likeUIUpdate: likeUIUpdateRelay.asDriver(onErrorDriveWith: .empty())
        )
    }
}
