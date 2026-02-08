//
//  PurchaseHistoryViewModel.swift
//  Filo
//
//  Created by 이상민 on 2/8/26.
//

import Foundation
import RxSwift
import RxCocoa

final class PurchaseHistoryViewModel: ViewModelType {
    struct Input {
        let viewWillAppear: Observable<Void>
        let selectedOrder: Observable<OrderResponseDTO>
    }
    
    struct Output {
        let orders: Driver<[OrderResponseDTO]>
        let receipt: Signal<ReceiptOrderResponseDTO>
        let networkError: Signal<NetworkError>
    }
    
    private let service: NetworkManagerProtocol
    private let disposeBag = DisposeBag()
    
    init(service: NetworkManagerProtocol = NetworkManager.shared) {
        self.service = service
    }
    
    func transform(input: Input) -> Output {
        let ordersRelay = BehaviorRelay<[OrderResponseDTO]>(value: [])
        let receiptRelay = PublishRelay<ReceiptOrderResponseDTO>()
        let errorRelay = PublishRelay<NetworkError>()
        
        input.viewWillAppear
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                Task {
                    do {
                        let dto: OrderListResponseDTO = try await self.service.request(OrderRouter.fetchOrders)
                        ordersRelay.accept(dto.data)
                    } catch let error as NetworkError {
                        errorRelay.accept(error)
                    } catch {
                        errorRelay.accept(.unknown(error))
                    }
                }
            })
            .disposed(by: disposeBag)
        
        input.selectedOrder
            .subscribe(onNext: { [weak self] order in
                guard let self else { return }
                Task {
                    do {
                        let dto: PaymentResponseDTO = try await self.service.request(
                            PaymentRouter.payments(orderCode: order.orderCode)
                        )
                        let receipt = ReceiptOrderResponseDTO(
                            paymentId: dto.impUid,
                            orderItem: order,
                            createdAt: dto.createdAt,
                            updatedAt: dto.updatedAt
                        )
                        receiptRelay.accept(receipt)
                    } catch let error as NetworkError {
                        errorRelay.accept(error)
                    } catch {
                        errorRelay.accept(.unknown(error))
                    }
                }
            })
            .disposed(by: disposeBag)
        
        return Output(
            orders: ordersRelay.asDriver(onErrorDriveWith: .empty()),
            receipt: receiptRelay.asSignal(),
            networkError: errorRelay.asSignal()
        )
    }
}
