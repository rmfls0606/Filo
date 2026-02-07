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
    enum Mode {
        case create
        case edit(Seed)
    }

    struct Seed {
        let postId: String
        let title: String
        let content: String
        let category: searchCategoryType
        let latitude: Double
        let longitude: Double
        let files: [String]
    }

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
    private let mode: Mode

    var seed: Seed? {
        if case .edit(let seed) = mode { return seed }
        return nil
    }

    var isEditMode: Bool {
        if case .edit = mode { return true }
        return false
    }
    
    init(mode: Mode = .create, service: NetworkManagerProtocol = NetworkManager.shared) {
        self.service = service
        self.mode = mode
    }
    
    func transform(input: Input) -> Output {
        let mediaRelay = BehaviorRelay<[PostMediaItem]>(value: [])
        let initialCategory = seed?.category ?? .all
        let categoryRelay = BehaviorRelay<searchCategoryType>(value: initialCategory)
        let titleRelay = BehaviorRelay<String>(value: seed?.title ?? "")
        let contentRelay = BehaviorRelay<String>(value: seed?.content ?? "")
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
                return self?.isSubmitEnabled(title: title,
                                             content: content,
                                             category: category,
                                             media: media) ?? false
            }
            .distinctUntilChanged()
        
        let submitSource = Observable.combineLatest(titleRelay, contentRelay, categoryRelay, mediaRelay)
        input.submitTapped
            .withLatestFrom(submitSource)
            .subscribe(onNext: { [weak self] title, content, category, media in
                guard let self else { return }
                let validMedia = media.filter { $0.isValid }
                guard self.isSubmitEnabled(title: title,
                                           content: content,
                                           category: category,
                                           media: media) else { return }
                
                Task {
                    do {
                        let validMedia = media.filter { $0.isValid }
                        let files = validMedia.compactMap { item -> MultipartFile? in
                            guard let data = item.data,
                                  let fileName = item.fileName,
                                  let mimeType = item.mimeType else { return nil }
                            return MultipartFile(data: data,
                                                 name: "files",
                                                 fileName: fileName,
                                                 mimeType: mimeType)
                        }
                        #if DEBUG
                        let totalCount = files.count
                        let totalBytes = files.reduce(0) { $0 + $1.data.count }
                        print("[Upload] files.count=\(totalCount), totalBytes=\(totalBytes)")
                        for (idx, file) in files.enumerated() {
                            print("[Upload] #\(idx) name=\(file.fileName) mime=\(file.mimeType) bytes=\(file.data.count)")
                        }
                        #endif
                        if self.isEditMode, let seed = self.seed {
                            let existingFiles = validMedia.compactMap { $0.remotePath }
                            let uploadTargets = validMedia.filter { $0.remotePath == nil }
                            let uploadFiles = uploadTargets.compactMap { item -> MultipartFile? in
                                guard let data = item.data,
                                      let fileName = item.fileName,
                                      let mimeType = item.mimeType else { return nil }
                                return MultipartFile(data: data,
                                                     name: "files",
                                                     fileName: fileName,
                                                     mimeType: mimeType)
                            }
                            let uploaded: [String]
                            if uploadFiles.isEmpty {
                                uploaded = []
                            } else {
                                let filesDTO: PostFileResponseDTO = try await self.service.upload(
                                    CommunityRouter.files(files: []),
                                    files: uploadFiles
                                )
                                uploaded = filesDTO.files
                            }
                            let mergedFiles = existingFiles + uploaded
                            let _: PostResponseDTO = try await self.service.request(
                                CommunityRouter.put(
                                    postId: seed.postId,
                                    category: category.query,
                                    title: title,
                                    content: content,
                                    latitude: seed.latitude,
                                    longitude: seed.longitude,
                                    files: mergedFiles
                                )
                            )
                        } else {
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
                        }
                        
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
        guard media.allSatisfy({ $0.isValid }) else { return false }
        let hasExistingFiles = media.contains { $0.remotePath != nil }
        let hasNewFiles = media.contains { $0.remotePath == nil }
        return hasExistingFiles || hasNewFiles
    }
}
