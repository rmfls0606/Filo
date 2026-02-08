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
    private let service: NetworkManagerProtocol
    private let disposeBag = DisposeBag()

    init(receipt: ReceiptOrderResponseDTO,
         service: NetworkManagerProtocol = NetworkManager.shared) {
        self.receipt = receipt
        self.service = service
    }
    
    struct Input {
        let viewWillAppear: Observable<Void>
    }

    struct Output {
        let receipt: Driver<ReceiptOrderResponseDTO>
        let orderFilter: Driver<FilterSummaryResponseDTO_Order?>
        let paymentInfo: Driver<PaymentResponseDTO?>
        let networkError: Signal<NetworkError>
    }

    func transform(input: Input) -> Output {
        let paymentRelay = BehaviorRelay<PaymentResponseDTO?>(value: nil)
        let errorRelay = PublishRelay<NetworkError>()
        
        input.viewWillAppear
            .subscribe(onNext: { [weak self] in
                guard let self,
                      let orderCode = self.receipt.orderItem?.orderCode else { return }
                Task {
                    do {
                        let dto: PaymentResponseDTO = try await self.service.request(
                            PaymentRouter.payments(orderCode: orderCode)
                        )
                        paymentRelay.accept(dto)
                    } catch let error as NetworkError {
                        errorRelay.accept(error)
                    } catch {
                        errorRelay.accept(.unknown(error))
                    }
                }
            })
            .disposed(by: disposeBag)
        
        return Output(
            receipt: Driver.just(receipt),
            orderFilter: Driver.just(receipt.orderItem?.filter),
            paymentInfo: paymentRelay.asDriver(),
            networkError: errorRelay.asSignal()
        )
    }
}
