//
//  FilterViewModel.swift
//  Filo
//
//  Created by 이상민 on 12/18/25.
//

import Foundation
import RxSwift
import RxCocoa

final class FilterViewModel: ViewModelType{
    private let disposeBag = DisposeBag()
    
    struct Input{
        let categorySelected: Observable<FilterCategoryType>
    }
    
    struct Output{
        let categories: Driver<[FilterCategoryEntity]>
    }
    
    func transform(input: Input) -> Output {
        let categoriesRelay = BehaviorRelay<[FilterCategoryEntity]>(
            value: FilterCategoryType.allCases.map{
                FilterCategoryEntity(type: $0)
            }
        )
        
        input.categorySelected
            .withLatestFrom(categoriesRelay){ selected, items in
                items.map{
                    var newItems = $0
                    newItems.isSelected = ($0.type == selected)
                    return newItems
                }
            }
            .bind(to: categoriesRelay)
            .disposed(by: disposeBag)
        
        return Output(
            categories: categoriesRelay.asDriver()
        )
    }
}
