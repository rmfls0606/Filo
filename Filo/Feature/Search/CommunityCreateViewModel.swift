//
//  CommunityCreateViewModel.swift
//  Filo
//
//  Created by 이상민 on 2/7/26.
//

import Foundation
import RxSwift
import RxCocoa

final class CommunityCreateViewModel: ViewModelType {
    struct Input {
        let titleText: Observable<String>
        let contentText: Observable<String>
        let categorySelected: Observable<searchCategoryType>
        let mediaAppend: Observable<[PostMediaItem]>
        let mediaRemoveAt: Observable<Int>
        let submitTapped: Observable<Void>
    }
    
    struct Output {
        let mediaItems: Driver<[PostMediaItem]>
        let submitEnabled: Driver<Bool>
        let submitSuccess: Signal<Void>
        let networkError: Signal<NetworkError>
    }
    
    private let disposeBag = DisposeBag()
    private let service: NetworkManagerProtocol
    
    init(service: NetworkManagerProtocol = NetworkManager.shared) {
        self.service = service
    }
    
    func transform(input: Input) -> Output {
        let mediaRelay = BehaviorRelay<[PostMediaItem]>(value: [])
        let categoryRelay = BehaviorRelay<searchCategoryType>(value: .all)
        let titleRelay = BehaviorRelay<String>(value: "")
        let contentRelay = BehaviorRelay<String>(value: "")
        let errorRelay = PublishRelay<NetworkError>()
        let successRelay = PublishRelay<Void>()
        
        input.categorySelected
            .bind(to: categoryRelay)
            .disposed(by: disposeBag)
        
        input.titleText
            .bind(to: titleRelay)
            .disposed(by: disposeBag)
        
        input.contentText
            .bind(to: contentRelay)
            .disposed(by: disposeBag)
        
        input.mediaAppend
            .subscribe(onNext: { items in
                var current = mediaRelay.value
                current.append(contentsOf: items)
                if current.count > 5 {
                    current = Array(current.prefix(5))
                }
                mediaRelay.accept(current)
            })
            .disposed(by: disposeBag)
        
        input.mediaRemoveAt
            .subscribe(onNext: { index in
                var current = mediaRelay.value
                guard current.indices.contains(index) else { return }
                current.remove(at: index)
                mediaRelay.accept(current)
            })
            .disposed(by: disposeBag)
        
        let submitEnabled = Observable
            .combineLatest(titleRelay, contentRelay, categoryRelay, mediaRelay)
            .map { [weak self] title, content, category, media in
                let validMedia = media.filter { $0.isValid }
                return self?.isSubmitEnabled(title: title, content: content, category: category, media: validMedia) ?? false
            }
            .distinctUntilChanged()
        
        let submitSource = Observable.combineLatest(titleRelay, contentRelay, categoryRelay, mediaRelay)
        input.submitTapped
            .withLatestFrom(submitSource)
            .subscribe(onNext: { [weak self] title, content, category, media in
                guard let self else { return }
                let validMedia = media.filter { $0.isValid }
                guard self.isSubmitEnabled(title: title, content: content, category: category, media: validMedia) else { return }
                
                Task {
                    do {
                        let files = validMedia.compactMap { item -> MultipartFile? in
                            guard let data = item.data,
                                  let fileName = item.fileName,
                                  let mimeType = item.mimeType else { return nil }
                            return MultipartFile(data: data,
                                                 name: "files",
                                                 fileName: fileName,
                                                 mimeType: mimeType)
                        }
                        let filesDTO: PostFileResponseDTO = try await self.service.upload(
                            CommunityRouter.files(files: []),
                            files: files
                        )
                        
                        let _: PostResponseDTO = try await self.service.request(
                            CommunityRouter.posts(
                                category: category.query,
                                title: title,
                                content: content,
                                files: filesDTO.files
                            )
                        )
                        
                        successRelay.accept(())
                    } catch let error as NetworkError {
                        errorRelay.accept(error)
                    } catch {
                        errorRelay.accept(.unknown(error))
                    }
                }
            })
            .disposed(by: disposeBag)
        
        return Output(
            mediaItems: mediaRelay.asDriver(),
            submitEnabled: submitEnabled.asDriver(onErrorJustReturn: false),
            submitSuccess: successRelay.asSignal(),
            networkError: errorRelay.asSignal()
        )
    }

    private func isSubmitEnabled(title: String,
                                 content: String,
                                 category: searchCategoryType,
                                 media: [PostMediaItem]) -> Bool {
        guard category != .all else { return false }
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        return !media.isEmpty
    }
}
