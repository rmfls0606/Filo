//
//  MyFilterListViewModel.swift
//  Filo
//
//  Created by 이상민 on 2/8/26.
//

import Foundation
import RxSwift
import RxCocoa

final class MyFilterListViewModel: ViewModelType {
    struct Input {
        let viewWillAppear: Observable<Void>
        let selectedItem: Observable<FilterSummaryResponseEntity>
    }
    
    struct Output {
        let filters: Driver<[FilterSummaryResponseEntity]>
        let selectedFilterId: Driver<String>
        let networkError: Signal<NetworkError>
    }
    
    private let service: NetworkManagerProtocol
    private let disposeBag = DisposeBag()
    
    init(service: NetworkManagerProtocol = NetworkManager.shared) {
        self.service = service
    }
    
    func transform(input: Input) -> Output {
        let filtersRelay = BehaviorRelay<[FilterSummaryResponseEntity]>(value: [])
        let selectedRelay = PublishRelay<String>()
        let errorRelay = PublishRelay<NetworkError>()
        
        input.viewWillAppear
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                Task {
                    do {
                        let currentUserId = (try? KeychainManager.shared.read(key: .userId)) ?? ""
                        guard !currentUserId.isEmpty else { return }
                        let dto: FilterSummaryPaginationListResponseDTO = try await self.service.request(
                            FilterRouter.user(userId: currentUserId, next: "", limit: "30", category: "")
                        )
                        let entity = dto.toEntity()
                        entity.data.forEach { item in
                            LikeStore.shared.setLiked(id: item.filterId, liked: item.isLiked, count: item.likeCount)
                        }
                        filtersRelay.accept(entity.data)
                    } catch let error as NetworkError {
                        errorRelay.accept(error)
                    } catch {
                        errorRelay.accept(.unknown(error))
                    }
                }
            })
            .disposed(by: disposeBag)
        
        input.selectedItem
            .map { $0.filterId }
            .bind(to: selectedRelay)
            .disposed(by: disposeBag)
        
        return Output(
            filters: filtersRelay.asDriver(onErrorDriveWith: .empty()),
            selectedFilterId: selectedRelay.asDriver(onErrorDriveWith: .empty()),
            networkError: errorRelay.asSignal()
        )
    }
}
