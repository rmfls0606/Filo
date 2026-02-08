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
        let likeFilterTap: Observable<String>
        let likePostTap: Observable<PostSummaryResponseDTO>
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
                        postDto.data.forEach { item in
                            LikeStore.shared.setLiked(id: item.postId, liked: item.isLike, count: item.likeCount)
                        }
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
        
        var filterRequestIdById: [String: Int] = [:]
        var filterLatestRequestIdById: [String: Int] = [:]
        
        input.likeFilterTap
            .groupBy { $0 }
            .flatMap { [weak self] group -> Observable<Void> in
                guard let self else { return .empty() }
                return group
                    .map { filterId -> (id: String, desiredLiked: Bool, requestId: Int, prevLiked: Bool, prevCount: Int, optimisticCount: Int) in
                        let prevLiked = LikeStore.shared.isLiked(id: filterId)
                        let prevCount = LikeStore.shared.likeCount(id: filterId) ?? 0
                        let desiredLiked = !prevLiked
                        let optimisticCount = max(0, prevCount + (desiredLiked ? 1 : -1))
                        LikeStore.shared.setLiked(id: filterId, liked: desiredLiked, count: optimisticCount)
                        
                        let requestId = (filterRequestIdById[filterId] ?? 0) + 1
                        filterRequestIdById[filterId] = requestId
                        filterLatestRequestIdById[filterId] = requestId
                        
                        return (filterId, desiredLiked, requestId, prevLiked, prevCount, optimisticCount)
                    }
                    .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
                    .flatMapLatest { payload -> Observable<Void> in
                        let id = payload.id
                        let requestId = payload.requestId
                        let desiredLiked = payload.desiredLiked
                        let prevLiked = payload.prevLiked
                        let prevCount = payload.prevCount
                        
                        return Observable<Bool>.create { observer in
                            Task {
                                do {
                                    let dto: FilterLikeResponseDTO = try await self.service.request(
                                        FilterRouter.like(filterId: id, liked: desiredLiked)
                                    )
                                    observer.onNext(dto.likeStatus)
                                    observer.onCompleted()
                                } catch {
                                    observer.onError(error)
                                }
                            }
                            return Disposables.create()
                        }
                        .flatMap { likedNow -> Observable<Void> in
                            guard filterLatestRequestIdById[id] == requestId else { return .empty() }
                            let baseCount = LikeStore.shared.likeCount(id: id) ?? prevCount
                            let finalCount: Int
                            if likedNow == desiredLiked {
                                finalCount = baseCount
                            } else {
                                finalCount = max(0, baseCount + (likedNow ? 1 : -1))
                            }
                            LikeStore.shared.setLiked(id: id, liked: likedNow, count: finalCount)
                            if !likedNow {
                                let filtered = filtersRelay.value.filter { $0.filterId != id }
                                filtersRelay.accept(filtered)
                            }
                            return .just(())
                        }
                        .catch { error in
                            guard filterLatestRequestIdById[id] == requestId else { return .empty() }
                            LikeStore.shared.setLiked(id: id, liked: prevLiked, count: prevCount)
                            errorRelay.accept(error as? NetworkError ?? .unknown(error))
                            return .just(())
                        }
                    }
            }
            .subscribe()
            .disposed(by: disposeBag)
        
        var postRequestIdById: [String: Int] = [:]
        var postLatestRequestIdById: [String: Int] = [:]
        
        input.likePostTap
            .groupBy { $0.postId }
            .flatMap { [weak self] group -> Observable<Void> in
                guard let self else { return .empty() }
                return group
                    .map { item -> (id: String, desiredLiked: Bool, requestId: Int, prevLiked: Bool, prevCount: Int, optimisticCount: Int, originalCount: Int) in
                        let prevLiked = LikeStore.shared.isLiked(id: item.postId)
                        let prevCount = LikeStore.shared.likeCount(id: item.postId) ?? item.likeCount
                        let desiredLiked = !prevLiked
                        let optimisticCount = max(0, prevCount + (desiredLiked ? 1 : -1))
                        LikeStore.shared.setLiked(id: item.postId, liked: desiredLiked, count: optimisticCount)
                        
                        let requestId = (postRequestIdById[item.postId] ?? 0) + 1
                        postRequestIdById[item.postId] = requestId
                        postLatestRequestIdById[item.postId] = requestId
                        
                        return (item.postId, desiredLiked, requestId, prevLiked, prevCount, optimisticCount, item.likeCount)
                    }
                    .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
                    .flatMapLatest { payload -> Observable<Void> in
                        let id = payload.id
                        let requestId = payload.requestId
                        let desiredLiked = payload.desiredLiked
                        let prevLiked = payload.prevLiked
                        let prevCount = payload.prevCount
                        let originalCount = payload.originalCount
                        
                        return Observable<Bool>.create { observer in
                            Task {
                                do {
                                    let dto: PostLikeResponseDTO = try await self.service.request(
                                        CommunityRouter.like(postId: id, isLike: desiredLiked)
                                    )
                                    observer.onNext(dto.likeStatus)
                                    observer.onCompleted()
                                } catch {
                                    observer.onError(error)
                                }
                            }
                            return Disposables.create()
                        }
                        .flatMap { likedNow -> Observable<Void> in
                            guard postLatestRequestIdById[id] == requestId else { return .empty() }
                            let baseCount = LikeStore.shared.likeCount(id: id) ?? originalCount
                            let finalCount: Int
                            if likedNow == desiredLiked {
                                finalCount = baseCount
                            } else {
                                finalCount = max(0, baseCount + (likedNow ? 1 : -1))
                            }
                            LikeStore.shared.setLiked(id: id, liked: likedNow, count: finalCount)
                            if !likedNow {
                                let filtered = postsRelay.value.filter { $0.postId != id }
                                postsRelay.accept(filtered)
                            }
                            return .just(())
                        }
                        .catch { error in
                            guard postLatestRequestIdById[id] == requestId else { return .empty() }
                            LikeStore.shared.setLiked(id: id, liked: prevLiked, count: prevCount)
                            errorRelay.accept(error as? NetworkError ?? .unknown(error))
                            return .just(())
                        }
                    }
            }
            .subscribe()
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
