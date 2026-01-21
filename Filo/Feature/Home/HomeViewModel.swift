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
    struct Input{
        
    }
    
    struct Output{
        let filterCategories: Driver<[FilterCategoryType]>
    }
    
    func transform(input: Input) -> Output {
        let filterCategoriesRelay = BehaviorRelay<[FilterCategoryType]>(value: FilterCategoryType.allCases)
        return Output(
            filterCategories: filterCategoriesRelay.asDriver()
        )
    }
}
