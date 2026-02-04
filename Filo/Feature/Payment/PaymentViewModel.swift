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
    private let disposeBag = DisposeBag()
    
    init(product: [FilterResponseDTO]) {
        self.product = product
    }
    
    struct Input{
        let buyButtonTapped: ControlEvent<Void>
        let paymentValidationId: PublishRelay<String?>
    }
    
    struct Output{
        let orderItems: Driver<[FilterResponseDTO]>
        let totalPrice: Driver<Int>
        let paymentInfo: Driver<PaymentInfo>
        let validationResult: Signal<ReceiptOrderResponseDTO>
        let networkError: Signal<NetworkError>
    }
    
    func transform(input: Input) -> Output {
        let orderItemsRelay = BehaviorRelay<[FilterResponseDTO]>(value: product)
        let totalPriceRelay = BehaviorRelay<Int>(value: product.map{$0.price}.reduce(0, +))
        let paymentInfoRelay = PublishRelay<PaymentInfo>()
        let validationResultRelay = PublishRelay<ReceiptOrderResponseDTO>()
        let networkErrorRelay = PublishRelay<NetworkError>()

        let orderItems = Observable.combineLatest(orderItemsRelay, totalPriceRelay)
            .share(replay: 1)
        
        input.buyButtonTapped
            .withLatestFrom(orderItems)
            .subscribe(onNext: { product, totalPrice in
                guard let first = product.first else { return }
                Task{
                    do{
                        guard let buyerName = (await TokenStorage.shared.userName()).flatMap({
                            let trimmed = $0.trimmingCharacters(in: .whitespacesAndNewlines)
                            return trimmed.isEmpty ? nil : trimmed
                        }) else { return }
                        let dto: OrderCreateResponseDTO = try await NetworkManager.shared.request(
                            OrderRouter.order(filterId: first.filterId, totalPrice: totalPrice)
                        )
                        let info = PaymentInfo(
                            merchantUId: dto.orderCode,
                            totalPrice: "\(dto.totalPrice)",
                            productName: first.title,
                            buyerName: buyerName
                        )
                        paymentInfoRelay.accept(info)
                    }catch let error as NetworkError{
                        networkErrorRelay.accept(error)
                    }catch let error{
                        networkErrorRelay.accept(NetworkError.unknown(error))
                    }
                }
            })
            .disposed(by: disposeBag)
        
        input.paymentValidationId
            .compactMap{ $0 }
            .subscribe { impUId in
                Task{
                    do{
                        let dto: ReceiptOrderResponseDTO = try await NetworkManager.shared.request(PaymentRouter.validation(impUId: impUId))
                        validationResultRelay.accept(dto)
                    }catch let error as NetworkError{
                        networkErrorRelay.accept(error)
                    }catch let error{
                        networkErrorRelay.accept(NetworkError.unknown(error))
                    }
                }
            }
            .disposed(by: disposeBag)
        
        return Output(
            orderItems: orderItemsRelay.asDriver(),
            totalPrice: totalPriceRelay.asDriver(),
            paymentInfo: paymentInfoRelay.asDriver(onErrorDriveWith: .empty()),
            validationResult: validationResultRelay.asSignal(),
            networkError: networkErrorRelay.asSignal()
        )
    }
}
