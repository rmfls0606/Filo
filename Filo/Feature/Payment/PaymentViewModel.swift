//
//  PaymentViewModel.swift
//  Filo
//
//  Created by 이상민 on 2/4/26.
//

import UIKit
import RxSwift
import RxCocoa

final class PaymentViewModel: ViewModelType {
    let product: [FilterResponseDTO]
    
    init(product: [FilterResponseDTO]) {
        self.product = product
    }
    
    struct Input{
        
    }
    
    struct Output{
        let orderItems: Driver<[FilterResponseDTO]>
        let totalPrice: Driver<Int>
    }
    
    func transform(input: Input) -> Output {
        let orderItemsRelay = BehaviorRelay<[FilterResponseDTO]>(value: product)
        let totalPriceRelay = BehaviorRelay<Int>(value: product.map{$0.price}.reduce(0, +))
        
        return Output(
            orderItems: orderItemsRelay.asDriver(),
            totalPrice: totalPriceRelay.asDriver()
        )
    }
}
