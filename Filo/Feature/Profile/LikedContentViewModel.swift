//
//  LikedContentViewModel.swift
//  Filo
//
//  Created by 이상민 on 2/8/26.
//

import Foundation
import RxSwift
import RxCocoa

final class LikedContentViewModel: ViewModelType {
    struct Input {
        let viewWillAppear: Observable<Void>
        let filterTabTapped: Observable<Void>
        let postTabTapped: Observable<Void>
        let selectedFilter: Observable<FilterSummaryResponseEntity>
        let selectedPost: Observable<PostSummaryResponseDTO>
    }
    
    struct Output {
        let filters: Driver<[FilterSummaryResponseEntity]>
        let posts: Driver<[PostSummaryResponseDTO]>
        let selectedSegment: Driver<Int>
        let selectedFilterId: Driver<String>
        let selectedPostId: Driver<String>
        let networkError: Signal<NetworkError>
    }
    
    private let service: NetworkManagerProtocol
    private let disposeBag = DisposeBag()
    
    init(service: NetworkManagerProtocol = NetworkManager.shared) {
        self.service = service
    }
    
    func transform(input: Input) -> Output {
        let filtersRelay = BehaviorRelay<[FilterSummaryResponseEntity]>(value: [])
        let postsRelay = BehaviorRelay<[PostSummaryResponseDTO]>(value: [])
        let selectedSegmentRelay = BehaviorRelay<Int>(value: 0)
        let selectedFilterRelay = PublishRelay<String>()
        let selectedPostRelay = PublishRelay<String>()
        let errorRelay = PublishRelay<NetworkError>()
        
        input.filterTabTapped
            .map { 0 }
            .bind(to: selectedSegmentRelay)
            .disposed(by: disposeBag)
        
        input.postTabTapped
            .map { 1 }
            .bind(to: selectedSegmentRelay)
            .disposed(by: disposeBag)
        
        input.viewWillAppear
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                Task {
                    do {
                        let filterDto: FilterSummaryPaginationListResponseDTO = try await self.service.request(
                            FilterRouter.likesMe(category: "", next: "", limit: "30")
                        )
                        let entity = filterDto.toEntity()
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
                
                Task {
                    do {
                        let postDto: PostSummaryPaginationResponseDTO = try await self.service.request(
                            CommunityRouter.likesMe(category: "", limit: "30", next: "")
                        )
                        postsRelay.accept(postDto.data)
                    } catch let error as NetworkError {
                        errorRelay.accept(error)
                    } catch {
                        errorRelay.accept(.unknown(error))
                    }
                }
            })
            .disposed(by: disposeBag)
        
        input.selectedFilter
            .map { $0.filterId }
            .bind(to: selectedFilterRelay)
            .disposed(by: disposeBag)
        
        input.selectedPost
            .map { $0.postId }
            .bind(to: selectedPostRelay)
            .disposed(by: disposeBag)
        
        return Output(
            filters: filtersRelay.asDriver(onErrorDriveWith: .empty()),
            posts: postsRelay.asDriver(onErrorDriveWith: .empty()),
            selectedSegment: selectedSegmentRelay.asDriver(),
            selectedFilterId: selectedFilterRelay.asDriver(onErrorDriveWith: .empty()),
            selectedPostId: selectedPostRelay.asDriver(onErrorDriveWith: .empty()),
            networkError: errorRelay.asSignal()
        )
    }
}
