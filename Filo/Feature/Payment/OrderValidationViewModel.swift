//
//  OrderValidationViewModel.swift
//  Filo
//
//  Created by 이상민 on 2/5/26.
//

import Foundation
import RxSwift
import RxCocoa

final class OrderValidationViewModel: ViewModelType {
    private let receipt: ReceiptOrderResponseDTO

    init(receipt: ReceiptOrderResponseDTO) {
        self.receipt = receipt
    }
    
    struct Input { }

    struct Output {
    
    }

    func transform(input: Input) -> Output {
        return Output(
          
        )
    }
}
