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
    }
    
    func transform(input: Input) -> Output {
        let selectedOrderRelay = BehaviorRelay<OrderByItem>(value: .popularity)
        
        input.orderByItemSelected
            .bind(to: selectedOrderRelay)
            .disposed(by: disposeBag)

        return Output(
            selectedOrder: selectedOrderRelay.asDriver()
        )
    }
}
