//
//  CommunityCreateViewController.swift
//  Filo
//
//  Created by 이상민 on 2/7/26.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import PhotosUI
import UniformTypeIdentifiers
import AVFoundation

final class CommunityCreateViewController: BaseViewController {
    private let viewModel: CommunityCreateViewModel
    private let disposeBag = DisposeBag()
    
    private let mediaAppendRelay = PublishRelay<[PostMediaItem]>()
    private let mediaRemoveRelay = PublishRelay<Int>()
    private let categoryRelay = PublishRelay<searchCategoryType>()
    private static func makeCategories() -> [SearchCategoryItem] {
        let categories = searchCategoryType.allCases.filter { $0 != .all }
        return categories.map { SearchCategoryItem(type: $0, isSelected: false) }
    }

    private let categoriesRelay = BehaviorRelay<[SearchCategoryItem]>(value: CommunityCreateViewController.makeCategories())
    private var currentMediaItems: [PostMediaItem] = []
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let loadingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        view.isHidden = true
        return view
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.color = .white
        return indicator
    }()
    
    private let titleField: UITextField = {
        let field = UITextField()
        field.placeholder = "제목"
        field.font = .Pretendard.body2
        field.textColor = GrayStyle.gray45.color
        field.backgroundColor = GrayStyle.gray90.color
        field.layer.cornerRadius = 10
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        field.leftViewMode = .always
        return field
    }()
    
    private let contentTextView: UITextView = {
        let view = UITextView()
        view.font = .Pretendard.body2
        view.textColor = GrayStyle.gray45.color
        view.backgroundColor = GrayStyle.gray90.color
        view.layer.cornerRadius = 10
        view.textContainerInset = .init(top: 12, left: 8, bottom: 12, right: 8)
        return view
    }()
    
    private let contentPlaceholderLabel: UILabel = {
        let label = UILabel()
        label.text = "내용"
        label.font = .Pretendard.body2
        label.textColor = GrayStyle.gray75.color
        return label
    }()
    
    private let categoryCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 8
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.showsHorizontalScrollIndicator = false
        view.backgroundColor = .clear
        view.register(FilterCategoryCollectionViewCell.self, forCellWithReuseIdentifier: FilterCategoryCollectionViewCell.identifier)
        return view
    }()
    
    private let addMediaButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .capsule
        config.baseBackgroundColor = GrayStyle.gray90.color
        config.baseForegroundColor = GrayStyle.gray45.color
        config.title = "미디어 추가"
        let button = UIButton(configuration: config)
        return button
    }()
    
    private let mediaCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 6
        layout.minimumLineSpacing = 6
        layout.itemSize = .zero
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .clear
        view.register(CommunityMediaPreviewCell.self, forCellWithReuseIdentifier: CommunityMediaPreviewCell.identifier)
        view.showsVerticalScrollIndicator = true
        return view
    }()
    
    private let submitButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .capsule
        config.baseBackgroundColor = Brand.deepTurquoise.color
        config.baseForegroundColor = GrayStyle.gray45.color
        config.title = "등록"
        let button = UIButton(configuration: config)
        return button
    }()
    
    init(viewModel: CommunityCreateViewModel = CommunityCreateViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let layout = mediaCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            let width = (mediaCollectionView.bounds.width - 6 * 2) / 3
            let size = CGSize(width: max(0, width), height: max(0, width))
            if layout.itemSize != size {
                layout.itemSize = size
                layout.invalidateLayout()
            }
        }
    }
    
    override func configureHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        view.addSubview(loadingView)
        loadingView.addSubview(loadingIndicator)
        contentView.addSubview(categoryCollectionView)
        contentView.addSubview(titleField)
        contentView.addSubview(contentTextView)
        contentTextView.addSubview(contentPlaceholderLabel)
        contentView.addSubview(addMediaButton)
        contentView.addSubview(mediaCollectionView)
        contentView.addSubview(submitButton)
    }
    
    override func configureLayout() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        loadingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        categoryCollectionView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(16)
            make.horizontalEdges.equalToSuperview().inset(16)
            make.height.equalTo(36)
        }
        
        titleField.snp.makeConstraints { make in
            make.top.equalTo(categoryCollectionView.snp.bottom).offset(12)
            make.horizontalEdges.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }
        
        contentTextView.snp.makeConstraints { make in
            make.top.equalTo(titleField.snp.bottom).offset(12)
            make.horizontalEdges.equalToSuperview().inset(16)
            make.height.equalTo(160)
        }
        
        contentPlaceholderLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.top.equalToSuperview().inset(12)
        }
        
        addMediaButton.snp.makeConstraints { make in
            make.top.equalTo(contentTextView.snp.bottom).offset(12)
            make.leading.equalToSuperview().inset(16)
            make.height.equalTo(36)
        }
        
        mediaCollectionView.snp.makeConstraints { make in
            make.top.equalTo(addMediaButton.snp.bottom).offset(12)
            make.horizontalEdges.equalToSuperview().inset(16)
            make.height.equalTo(220)
        }
        
        submitButton.snp.makeConstraints { make in
            make.top.equalTo(mediaCollectionView.snp.bottom).offset(20)
            make.horizontalEdges.equalToSuperview().inset(16)
            make.height.equalTo(44)
            make.bottom.equalToSuperview().inset(24)
        }
    }
    
    override func configureView() {
        view.backgroundColor = GrayStyle.gray100.color
        navigationItem.title = "게시글 등록"
        hideKeyboardWhenTapped()
    }
    
    override func configureBind() {
        let input = CommunityCreateViewModel.Input(
            titleText: titleField.rx.text.orEmpty.asObservable(),
            contentText: contentTextView.rx.text.orEmpty.asObservable(),
            categorySelected: categoryRelay.asObservable(),
            mediaAppend: mediaAppendRelay.asObservable(),
            mediaRemoveAt: mediaRemoveRelay.asObservable(),
            submitTapped: submitButton.rx.tap.asObservable()
        )
        
        let output = viewModel.transform(input: input)
        
        categoriesRelay
            .bind(to: categoryCollectionView.rx.items(
                cellIdentifier: FilterCategoryCollectionViewCell.identifier,
                cellType: FilterCategoryCollectionViewCell.self
            )) { _, item, cell in
                cell.configure(title: item.type.rawValue, isSelected: item.isSelected)
            }
            .disposed(by: disposeBag)

        categoriesRelay
            .bind(with: self) { owner, _ in
                DispatchQueue.main.async {
                    owner.categoryCollectionView.collectionViewLayout.invalidateLayout()
                    owner.categoryCollectionView.layoutIfNeeded()
                }
            }
            .disposed(by: disposeBag)
        
        categoryCollectionView.rx.itemSelected
            .bind(with: self) { owner, indexPath in
                guard owner.categoriesRelay.value.indices.contains(indexPath.item) else { return }
                let selected = owner.categoriesRelay.value[indexPath.item]
                let updated = owner.categoriesRelay.value.map {
                    SearchCategoryItem(type: $0.type, isSelected: $0.type == selected.type)
                }
                owner.categoriesRelay.accept(updated)
                owner.categoryRelay.accept(selected.type)
            }
            .disposed(by: disposeBag)
        
        output.mediaItems
            .drive(with: self) { owner, items in
                owner.currentMediaItems = items
            }
            .disposed(by: disposeBag)

        output.mediaItems
            .drive(mediaCollectionView.rx.items(
                cellIdentifier: CommunityMediaPreviewCell.identifier,
                cellType: CommunityMediaPreviewCell.self
            )) { _, item, cell in
                cell.configure(item: item)
            }
            .disposed(by: disposeBag)
        
        output.submitEnabled
            .drive(with: self) { owner, enabled in
                owner.submitButton.alpha = enabled ? 1.0 : 0.4
            }
            .disposed(by: disposeBag)
        
        output.submitSuccess
            .emit(with: self) { owner, _ in
                owner.navigationController?.popViewController(animated: true)
            }
            .disposed(by: disposeBag)
        
        output.networkError
            .emit(with: self) { owner, error in
                owner.showAlert(title: "오류", message: error.errorDescription)
            }
            .disposed(by: disposeBag)

        submitButton.rx.tap
            .withLatestFrom(output.submitEnabled.asObservable())
            .filter { !$0 }
            .bind(with: self) { owner, _ in
                owner.showAlert(title: "안내", message: "카테고리, 제목, 내용, 미디어를 모두 입력해주세요.")
            }
            .disposed(by: disposeBag)
        
        addMediaButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.presentPicker()
            }
            .disposed(by: disposeBag)
        
        mediaCollectionView.rx.itemSelected
            .map { $0.item }
            .bind(to: mediaRemoveRelay)
            .disposed(by: disposeBag)
        
        contentTextView.rx.text.orEmpty
            .map { !$0.isEmpty }
            .bind(with: self) { owner, hasText in
                owner.contentPlaceholderLabel.isHidden = hasText
            }
            .disposed(by: disposeBag)
    }
}

private extension CommunityCreateViewController {
    func presentPicker() {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        let remaining = max(0, 5 - currentMediaItems.count)
        guard remaining > 0 else {
            showAlert(title: "안내", message: "파일은 최대 5개까지 등록 가능합니다.")
            return
        }
        config.selectionLimit = remaining
        config.filter = .any(of: [.images, .videos])
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func hideKeyboardWhenTapped() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func makeMediaItem(data: Data, fileName: String, mimeType: String, fileExtension: String, isVideo: Bool) -> PostMediaItem? {
        guard data.count <= 5 * 1024 * 1024 else { return nil }
        let image: UIImage?
        if isVideo {
            image = thumbnailFromVideo(data: data, fileExtension: fileExtension)
        } else {
            image = UIImage(data: data)
        }
        guard let image else { return nil }
        return PostMediaItem(
            id: UUID(),
            data: data,
            fileName: fileName,
            mimeType: mimeType,
            thumbnail: image,
            isVideo: isVideo,
            isValid: true
        )
    }
    
    func makeInvalidItem(thumbnail: UIImage?, isVideo: Bool) -> PostMediaItem {
        return PostMediaItem(
            id: UUID(),
            data: nil,
            fileName: nil,
            mimeType: nil,
            thumbnail: thumbnail ?? UIImage(),
            isVideo: isVideo,
            isValid: false
        )
    }
    
    enum ImageProcessResult {
        case success(PostMediaItem)
        case rejectedTooLarge(PostMediaItem)
        case failedCompression(PostMediaItem)
    }
    
    func makeImageItem(data: Data, mimeType: String, fileExtension: String) -> ImageProcessResult {
        let maxSize = 5 * 1024 * 1024
        let fileName = "post_media_\(UUID().uuidString).\(fileExtension)"
        if data.count <= maxSize, let item = makeMediaItem(data: data, fileName: fileName, mimeType: mimeType, fileExtension: fileExtension, isVideo: false) {
            return .success(item)
        }
        
        guard let image = UIImage(data: data) else {
            return .failedCompression(makeInvalidItem(thumbnail: nil, isVideo: false))
        }
        let resized = resizeImageIfNeeded(image, maxDimension: 1600)
        let qualities: [CGFloat] = [0.8, 0.6, 0.4, 0.3]
        for quality in qualities {
            if let jpgData = resized.jpegData(compressionQuality: quality), jpgData.count <= maxSize {
                let jpgName = "post_media_\(UUID().uuidString).jpg"
                if let item = makeMediaItem(data: jpgData, fileName: jpgName, mimeType: "image/jpeg", fileExtension: "jpg", isVideo: false) {
                    return .success(item)
                }
            }
        }
        
        return .rejectedTooLarge(makeInvalidItem(thumbnail: image, isVideo: false))
    }
    
    func resizeImageIfNeeded(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return image }
        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    func thumbnailFromVideo(data: Data, fileExtension: String) -> UIImage? {
        let ext = fileExtension.isEmpty ? "mp4" : fileExtension
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".\(ext)")
        try? data.write(to: tempURL)
        let asset = AVAsset(url: tempURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let time = CMTime(seconds: 0.0, preferredTimescale: 600)
        if let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) {
            return UIImage(cgImage: cgImage)
        }
        return nil
    }
    
    enum VideoProcessResult {
        case success(PostMediaItem)
        case rejectedTooLarge(PostMediaItem)
        case failedCompression(PostMediaItem)
    }
    
    func makeVideoItem(from url: URL, completion: @escaping (VideoProcessResult) -> Void) {
        let maxSize = 5 * 1024 * 1024
        if let originalSize = fileSizeBytes(url: url) {
            print("[Media] Original video size: \(originalSize) bytes")
        }
        if let data = try? Data(contentsOf: url), data.count <= maxSize {
            let (mime, fileName, ext) = mimeTypeAndName(from: url)
            let item = makeMediaItem(data: data, fileName: fileName, mimeType: mime, fileExtension: ext, isVideo: true)
            if let item {
                print("[Media] Video accepted without compression: \(data.count) bytes")
                completion(.success(item))
            } else {
                let thumb = thumbnailFromVideo(url: url)
                completion(.failedCompression(makeInvalidItem(thumbnail: thumb, isVideo: true)))
            }
            return
        }
        
        compressVideo(url: url, preset: AVAssetExportPresetMediumQuality) { [weak self] compressedURL in
            guard let self else {
                let invalid = PostMediaItem(
                    id: UUID(),
                    data: nil,
                    fileName: nil,
                    mimeType: nil,
                    thumbnail: UIImage(),
                    isVideo: true,
                    isValid: false
                )
                completion(.failedCompression(invalid))
                return
            }
            if let compressedURL, let data = try? Data(contentsOf: compressedURL), data.count <= maxSize {
                let fileName = "post_media_\(UUID().uuidString).mp4"
                let item = self.makeMediaItem(
                    data: data,
                    fileName: fileName,
                    mimeType: "video/mp4",
                    fileExtension: "mp4",
                    isVideo: true
                )
                if let item {
                    print("[Media] Video compressed (medium): \(data.count) bytes")
                    completion(.success(item))
                } else {
                    print("[Media] Video compressed (medium) but failed thumbnail")
                    let thumb = self.thumbnailFromVideo(url: url)
                    completion(.failedCompression(self.makeInvalidItem(thumbnail: thumb, isVideo: true)))
                }
                return
            }
            if let compressedURL, let data = try? Data(contentsOf: compressedURL) {
                print("[Media] Video compressed (medium) too large: \(data.count) bytes")
            }
            
            self.compressVideo(url: url, preset: AVAssetExportPresetLowQuality) { [weak self] fallbackURL in
                guard let self else {
                    let invalid = PostMediaItem(
                        id: UUID(),
                        data: nil,
                        fileName: nil,
                        mimeType: nil,
                        thumbnail: UIImage(),
                        isVideo: true,
                        isValid: false
                    )
                    completion(.failedCompression(invalid))
                    return
                }
                guard let fallbackURL, let data = try? Data(contentsOf: fallbackURL) else {
                    let thumb = self.thumbnailFromVideo(url: url)
                    completion(.failedCompression(self.makeInvalidItem(thumbnail: thumb, isVideo: true)))
                    return
                }
                guard data.count <= maxSize else {
                    print("[Media] Video compressed (low) too large: \(data.count) bytes")
                    let thumb = self.thumbnailFromVideo(url: url)
                    completion(.rejectedTooLarge(self.makeInvalidItem(thumbnail: thumb, isVideo: true)))
                    return
                }
                let fileName = "post_media_\(UUID().uuidString).mp4"
                let item = self.makeMediaItem(
                    data: data,
                    fileName: fileName,
                    mimeType: "video/mp4",
                    fileExtension: "mp4",
                    isVideo: true
                )
                if let item {
                    print("[Media] Video compressed (low): \(data.count) bytes")
                    completion(.success(item))
                } else {
                    print("[Media] Video compressed (low) but failed thumbnail")
                    let thumb = self.thumbnailFromVideo(url: url)
                    completion(.failedCompression(self.makeInvalidItem(thumbnail: thumb, isVideo: true)))
                }
            }
        }
    }

    func thumbnailFromVideo(url: URL) -> UIImage? {
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let time = CMTime(seconds: 0.0, preferredTimescale: 600)
        if let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) {
            return UIImage(cgImage: cgImage)
        }
        return nil
    }
    
    func showLoading() {
        loadingView.isHidden = false
        loadingIndicator.startAnimating()
    }
    
    func hideLoading() {
        loadingIndicator.stopAnimating()
        loadingView.isHidden = true
    }
    
    func compressVideo(url: URL, preset: String, completion: @escaping (URL?) -> Void) {
        let asset = AVURLAsset(url: url)
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: preset) else {
            completion(nil)
            return
        }
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                if exportSession.status == .completed {
                    completion(outputURL)
                } else {
                    completion(nil)
                }
            }
        }
    }
    
    func mimeTypeAndName(from url: URL) -> (String, String, String) {
        let ext = url.pathExtension.lowercased()
        let mime = UTType(filenameExtension: ext)?.preferredMIMEType ?? "application/octet-stream"
        let fileName = "post_media_\(UUID().uuidString).\(ext.isEmpty ? "bin" : ext)"
        return (mime, fileName, ext)
    }

    func detectMimeType(_ data: Data) -> String? {
        if data.count >= 12 {
            let bytes = [UInt8](data.prefix(12))
            if bytes[0] == 0xFF && bytes[1] == 0xD8 {
                return "image/jpeg"
            }
            if bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47 {
                return "image/png"
            }
            if bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46 {
                return "image/gif"
            }
            if bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
                bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50 {
                return "image/webp"
            }
        }
        return nil
    }
    
    func fileSizeBytes(url: URL) -> Int? {
        (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int) ?? nil
    }

    func fileExtension(for mimeType: String) -> String {
        switch mimeType {
        case "image/jpeg":
            return "jpg"
        case "image/png":
            return "png"
        case "image/gif":
            return "gif"
        case "image/webp":
            return "webp"
        default:
            return "bin"
        }
    }
}

extension CommunityCreateViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard !results.isEmpty else { return }
        
        var items: [PostMediaItem] = []
        let group = DispatchGroup()
        let lock = DispatchQueue(label: "community.create.media.lock")
        var rejectedCount = 0
        var rejectedTooLarge = 0
        var failedCompression = 0
        var unsupportedImage = 0
        var failedImageCompression = 0
        showLoading()
        
        results.forEach { result in
            group.enter()
            let provider = result.itemProvider
            
            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
                    defer { group.leave() }
                    guard let data else { return }
                    guard let mime = self.detectMimeType(data) else {
                        let invalid = self.makeInvalidItem(thumbnail: UIImage(data: data), isVideo: false)
                        lock.sync {
                            items.append(invalid)
                            rejectedCount += 1
                            unsupportedImage += 1
                        }
                        return
                    }
                    let ext = self.fileExtension(for: mime)
                    let result = self.makeImageItem(data: data, mimeType: mime, fileExtension: ext)
                    switch result {
                    case .success(let item):
                        lock.sync { items.append(item) }
                    case .rejectedTooLarge(let invalid):
                        lock.sync {
                            items.append(invalid)
                            rejectedCount += 1
                            rejectedTooLarge += 1
                        }
                    case .failedCompression(let invalid):
                        lock.sync {
                            items.append(invalid)
                            rejectedCount += 1
                            failedImageCompression += 1
                        }
                    }
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, _ in
                    guard let url else { lock.sync { rejectedCount += 1 }; group.leave(); return }
                    self.makeVideoItem(from: url) { result in
                        switch result {
                        case .success(let item):
                            lock.sync { items.append(item) }
                        case .rejectedTooLarge(let invalid):
                            lock.sync {
                                items.append(invalid)
                                rejectedCount += 1
                                rejectedTooLarge += 1
                            }
                        case .failedCompression(let invalid):
                            lock.sync {
                                items.append(invalid)
                                rejectedCount += 1
                                failedCompression += 1
                            }
                        }
                        group.leave()
                    }
                }
            } else {
                lock.sync { rejectedCount += 1 }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.hideLoading()
            if items.count > 5 {
                items = Array(items.prefix(5))
            }
            if items.isEmpty {
                self.showAlert(title: "오류", message: "파일 용량은 5MB 이하만 가능합니다.")
                return
            }
            self.mediaAppendRelay.accept(items)
            if rejectedCount > 0 {
                var messages: [String] = []
                if rejectedTooLarge > 0 {
                    messages.append("용량 제한(5MB)으로 제외된 파일이 \(rejectedTooLarge)개 있습니다.")
                }
                if failedCompression > 0 {
                    messages.append("영상 압축에 실패한 파일이 \(failedCompression)개 있습니다.")
                }
                if failedImageCompression > 0 {
                    messages.append("이미지 압축에 실패한 파일이 \(failedImageCompression)개 있습니다.")
                }
                if unsupportedImage > 0 {
                    messages.append("지원하지 않는 이미지 형식이 \(unsupportedImage)개 있습니다.")
                }
                let message = messages.isEmpty ? "처리할 수 없는 파일이 \(rejectedCount)개 있습니다." : messages.joined(separator: "\n")
                self.showAlert(title: "알림", message: message)
            }
        }
    }
}
