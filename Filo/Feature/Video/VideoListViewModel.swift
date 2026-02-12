import Foundation
import RxSwift
import RxCocoa

final class VideoListViewModel: ViewModelType {
    private let disposeBag = DisposeBag()

    struct Input {
        let initialLoad: Observable<Void>
        let loadNextPage: Observable<Void>
        let selectedVideo: Observable<VideoResponseDTO>
    }

    struct Output {
        let videos: Driver<[VideoResponseDTO]>
        let isInitialLoading: Driver<Bool>
        let isAppending: Driver<Bool>
        let selectedVideo: Driver<VideoResponseDTO>
        let networkError: Signal<NetworkError>
    }

    func transform(input: Input) -> Output {
        let videosRelay = BehaviorRelay<[VideoResponseDTO]>(value: [])
        let selectedVideoRelay = PublishRelay<VideoResponseDTO>()
        let networkErrorRelay = PublishRelay<NetworkError>()
        let isInitialLoadingRelay = BehaviorRelay<Bool>(value: false)
        let isAppendingRelay = BehaviorRelay<Bool>(value: false)
        let nextCursorRelay = BehaviorRelay<String?>(value: nil)
        let isLastPageRelay = BehaviorRelay<Bool>(value: false)

        let requestPage: (_ append: Bool) -> Void = { append in
            if append {
                guard !isAppendingRelay.value else { return }
                guard !isLastPageRelay.value else { return }
                guard let next = nextCursorRelay.value, !next.isEmpty else { return }
                isAppendingRelay.accept(true)
            } else {
                guard !isInitialLoadingRelay.value else { return }
                isInitialLoadingRelay.accept(true)
            }

            Task {
                do {
                    let next = append ? (nextCursorRelay.value ?? "") : ""
                    let dto: VideoListResponseDTO = try await NetworkManager.shared.request(
                        VideoRouter.videos(next: next, limit: 30)
                    )
                    dto.data.forEach { item in
                        LikeStore.shared.setLiked(id: item.videoId, liked: item.isLiked, count: item.likeCount)
                    }

                    let merged: [VideoResponseDTO]
                    if append {
                        merged = videosRelay.value + dto.data
                    } else {
                        merged = dto.data
                    }

                    videosRelay.accept(merged)

                    nextCursorRelay.accept(dto.nextCursor)
                    isLastPageRelay.accept(dto.nextCursor == nil)

                    if append {
                        isAppendingRelay.accept(false)
                    } else {
                        isInitialLoadingRelay.accept(false)
                    }
                } catch let error as NetworkError {
                    if append {
                        isAppendingRelay.accept(false)
                    } else {
                        isInitialLoadingRelay.accept(false)
                    }
                    networkErrorRelay.accept(error)
                } catch {
                    if append {
                        isAppendingRelay.accept(false)
                    } else {
                        isInitialLoadingRelay.accept(false)
                    }
                    networkErrorRelay.accept(.unknown(error))
                }
            }
        }

        input.initialLoad
            .subscribe(onNext: { _ in
                isLastPageRelay.accept(false)
                nextCursorRelay.accept(nil)
                requestPage(false)
            })
            .disposed(by: disposeBag)

        input.loadNextPage
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .subscribe(onNext: { _ in
                requestPage(true)
            })
            .disposed(by: disposeBag)

        input.selectedVideo
            .bind(to: selectedVideoRelay)
            .disposed(by: disposeBag)

        return Output(
            videos: videosRelay.asDriver(),
            isInitialLoading: isInitialLoadingRelay.asDriver(),
            isAppending: isAppendingRelay.asDriver(),
            selectedVideo: selectedVideoRelay.asDriver(onErrorDriveWith: .empty()),
            networkError: networkErrorRelay.asSignal()
        )
    }
}
