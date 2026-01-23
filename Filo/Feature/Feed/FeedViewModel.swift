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
    }
    
    struct Output{
        let selectedOrder: Driver<OrderByItem>
        let filtersData: Driver<FilterSummaryPaginationListResponseEntity>
    }
    
    func transform(input: Input) -> Output {
        let selectedOrderRelay = BehaviorRelay<OrderByItem>(value: .popularity)
        let filtersDataRelay = PublishRelay<FilterSummaryPaginationListResponseEntity>()
        let networkErrorRelay = PublishRelay<NetworkError>()
        let categoryRelay = BehaviorRelay<String>(value: category)
        
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
                        filtersDataRelay.accept(dto.toEntity())
                    }catch(let error as NetworkError){
                        print(error)
                        networkErrorRelay.accept(error)
                    }
                }
            })
            .disposed(by: disposeBag)

        return Output(
            selectedOrder: selectedOrderRelay.asDriver(),
            filtersData: filtersDataRelay.asDriver(onErrorDriveWith: .empty())
        )
    }
}
