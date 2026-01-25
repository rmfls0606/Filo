//
//  DetailViewModel.swift
//  Filo
//
//  Created by 이상민 on 1/25/26.
//

import UIKit
import RxSwift
import RxCocoa

final class DetailViewModel: ViewModelType {
    private let disposeBag = DisposeBag()
    
    private let filterIdRelay: BehaviorRelay<String>
    
    init(filterId: String) {
        self.filterIdRelay = BehaviorRelay(value: filterId)
    }
    
    struct Input{
        
    }
    
    struct Output{
        let filterDetailData: Driver<FilterResponseDTO>
    }
    
    func transform(input: Input) -> Output {
        let filterDetailDataRelay = PublishRelay<FilterResponseDTO>()
        let networkErrorRelay = PublishRelay<NetworkError>()
        
        filterIdRelay
            .subscribe(onNext: { filterId in
                Task{
                    do{
                        let dto: FilterResponseDTO = try await NetworkManager.shared.request(FilterRouter.detailFilter(filterId: filterId))
                        filterDetailDataRelay.accept(dto)
                    }catch(let error as NetworkError){
                        print(error)
                        networkErrorRelay.accept(error)
                    }
                }
            })
            .disposed(by: disposeBag)

        
        
        return Output(
            filterDetailData: filterDetailDataRelay.asDriver(onErrorDriveWith: .empty())
        )
    }
}
