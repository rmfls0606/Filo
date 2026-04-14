//
//  CommunityCreateViewController.swift
//  Filo
//
//  Created by 이상민 on 2/7/26.
//

import UIKit
import Toast
import SnapKit
import RxSwift
import RxCocoa
import PhotosUI
import UniformTypeIdentifiers
import AVFoundation
import ImageIO

final class CommunityCreateViewController: BaseViewController {
    private let viewModel: CommunityCreateViewModel
    private let disposeBag = DisposeBag()
    var onUpdated: (() -> Void)?
    var onCreated: (() -> Void)?
    
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
    private let formCardView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    private let categoryTitleLabel = CommunityCreateViewController.makeSectionLabel(text: "카테고리")
    private let titleSectionLabel = CommunityCreateViewController.makeSectionLabel(text: "제목")
    private let contentSectionLabel = CommunityCreateViewController.makeSectionLabel(text: "내용")
    private let mediaSectionLabel = CommunityCreateViewController.makeSectionLabel(text: "미디어")
    private let mediaCountLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.caption1
        label.textColor = GrayStyle.gray75.color
        label.text = "0/5"
        return label
    }()
    
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
        field.placeholder = "제목을 입력해주세요"
        field.font = .Pretendard.body2
        field.textColor = GrayStyle.gray30.color
        field.backgroundColor = .clear
        field.layer.cornerRadius = 10
        field.layer.borderWidth = 1.5
        field.layer.borderColor = Brand.deepTurquoise.color?.withAlphaComponent(0.5).cgColor
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        field.leftViewMode = .always
        field.tintColor = Brand.deepTurquoise.color
        return field
    }()
    
    private let contentTextView: UITextView = {
        let view = UITextView()
        view.font = .Pretendard.body2
        view.textColor = GrayStyle.gray30.color
        view.backgroundColor = .clear
        view.layer.cornerRadius = 10
        view.layer.borderWidth = 1.5
        view.layer.borderColor = Brand.deepTurquoise.color?.withAlphaComponent(0.5).cgColor
        view.textContainerInset = .init(top: 12, left: 8, bottom: 12, right: 8)
        view.tintColor = Brand.deepTurquoise.color
        return view
    }()
    
    private let contentPlaceholderLabel: UILabel = {
        let label = UILabel()
        label.text = "내용을 입력해주세요"
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
        let imageConfig = UIImage.SymbolConfiguration(scale: .medium)
        config.preferredSymbolConfigurationForImage = imageConfig
        config.cornerStyle = .capsule
        config.baseBackgroundColor = .clear
        config.baseForegroundColor = Brand.deepTurquoise.color
        config.image = UIImage(systemName: "plus")
        config.imagePadding = 2
        config.titlePadding = 2
        config.attributedTitle = AttributedString("미디어 추가", attributes: AttributeContainer([
            .font: UIFont.Pretendard.caption1 ?? UIFont.systemFont(ofSize: 12),
            .foregroundColor: Brand.deepTurquoise.color ?? UIColor.systemTeal
        ]))
        config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
        let button = UIButton(configuration: config)
        button.layer.borderWidth = 1.5
        button.layer.borderColor = Brand.deepTurquoise.color?.withAlphaComponent(0.5).cgColor
        return button
    }()
    
    private let mediaCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 6
        layout.minimumLineSpacing = 6
        layout.itemSize = .zero
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.isScrollEnabled = false
        view.backgroundColor = .clear
        view.register(CommunityMediaPreviewCell.self, forCellWithReuseIdentifier: CommunityMediaPreviewCell.identifier)
        view.showsVerticalScrollIndicator = false
        return view
    }()
    
    private var mediaCollectionHeightConstraint: Constraint?
    
    private let submitButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .capsule
        config.baseBackgroundColor = Brand.deepTurquoise.color
        config.baseForegroundColor = GrayStyle.gray30.color
        config.title = "등록"
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.Pretendard.body1
            return outgoing
        }
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
        contentView.addSubview(formCardView)
        formCardView.addSubview(categoryTitleLabel)
        formCardView.addSubview(categoryCollectionView)
        formCardView.addSubview(titleSectionLabel)
        formCardView.addSubview(titleField)
        formCardView.addSubview(contentSectionLabel)
        formCardView.addSubview(contentTextView)
        contentTextView.addSubview(contentPlaceholderLabel)
        formCardView.addSubview(mediaSectionLabel)
        formCardView.addSubview(mediaCountLabel)
        formCardView.addSubview(addMediaButton)
        formCardView.addSubview(mediaCollectionView)
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
        
        formCardView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(16)
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        
        categoryTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(18)
            make.horizontalEdges.equalToSuperview()
        }
        
        categoryCollectionView.snp.makeConstraints { make in
            make.top.equalTo(categoryTitleLabel.snp.bottom).offset(8)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(36)
        }
        
        titleSectionLabel.snp.makeConstraints { make in
            make.top.equalTo(categoryCollectionView.snp.bottom).offset(14)
            make.horizontalEdges.equalToSuperview()
        }
        
        titleField.snp.makeConstraints { make in
            make.top.equalTo(titleSectionLabel.snp.bottom).offset(8)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(44)
        }
        
        contentSectionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleField.snp.bottom).offset(14)
            make.horizontalEdges.equalToSuperview()
        }
        
        contentTextView.snp.makeConstraints { make in
            make.top.equalTo(contentSectionLabel.snp.bottom).offset(8)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(160)
        }
        
        contentPlaceholderLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.top.equalToSuperview().inset(12)
        }
        
        mediaSectionLabel.snp.makeConstraints { make in
            make.top.equalTo(contentTextView.snp.bottom).offset(12)
            make.leading.equalToSuperview()
        }
        
        mediaCountLabel.snp.makeConstraints { make in
            make.centerY.equalTo(mediaSectionLabel)
            make.trailing.equalToSuperview()
        }
        
        addMediaButton.snp.makeConstraints { make in
            make.top.equalTo(mediaSectionLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview()
        }
        
        mediaCollectionView.snp.makeConstraints { make in
            make.top.equalTo(addMediaButton.snp.bottom).offset(12)
            make.horizontalEdges.equalToSuperview()
            mediaCollectionHeightConstraint = make.height.equalTo(0).constraint
            make.bottom.equalToSuperview().inset(16)
        }
        
        submitButton.snp.makeConstraints { make in
            make.top.equalTo(formCardView.snp.bottom).offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(44)
            make.bottom.equalToSuperview().inset(24)
        }
    }
    
    override func configureView() {
        view.backgroundColor = GrayStyle.gray100.color
        navigationItem.title = viewModel.isEditMode ? "게시글 수정" : "게시글 등록"
        titleField.delegate = self
        contentTextView.delegate = self
        updateSubmitButton(enabled: false)
        if viewModel.isEditMode {
            var config = submitButton.configuration
            config?.title = "수정"
            submitButton.configuration = config
        }
        if let seed = viewModel.seed {
            titleField.text = seed.title
            contentTextView.text = seed.content
            contentPlaceholderLabel.isHidden = !seed.content.isEmpty
            let updated = categoriesRelay.value.map {
                SearchCategoryItem(type: $0.type, isSelected: $0.type == seed.category)
            }
            categoriesRelay.accept(updated)
        }
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

        if let seed = viewModel.seed, !seed.files.isEmpty {
            let items = seed.files.map { makeRemoteMediaItem(path: $0) }
            mediaAppendRelay.accept(items)
        }
        
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
            )) { [weak self] index, item, cell in
                cell.configure(item: item)
                cell.onDelete = { [weak self] in
                    self?.mediaRemoveRelay.accept(index)
                }
            }
            .disposed(by: disposeBag)

        mediaCollectionView.rx.observe(CGSize.self, "contentSize")
            .compactMap { $0?.height }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, height in
                owner.mediaCollectionHeightConstraint?.update(offset: height)
                owner.view.layoutIfNeeded()
            }
            .disposed(by: disposeBag)
        
        output.submitEnabled
            .drive(with: self) { owner, enabled in
                owner.updateSubmitButton(enabled: enabled)
            }
            .disposed(by: disposeBag)
        
        output.submitSuccess
            .emit(onNext: { [weak self] _ in
                guard let self else { return }
                if self.viewModel.isEditMode {
                    self.view.makeToast("정상적으로 수정이 완료되었습니다", duration: 1.0, position: .bottom)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        self.onUpdated?()
                        self.navigationController?.popViewController(animated: true)
                    }
                } else {
                    self.onCreated?()
                    self.navigationController?.popViewController(animated: true)
                }
            })
            .disposed(by: disposeBag)

        output.mediaItems
            .map(\.count)
            .drive(with: self) { owner, count in
                owner.mediaCountLabel.text = "\(count)/5"
            }
            .disposed(by: disposeBag)
        
        output.networkError
            .emit(with: self) { owner, error in
                owner.showAlert(title: "오류", message: error.errorDescription)
            }
            .disposed(by: disposeBag)

        submitButton.rx.tap
            .filter { [weak self] in
                self?.currentMediaItems.contains(where: { !$0.isValid }) ?? false
            }
            .bind(with: self) { owner, _ in
                owner.showAlert(title: "안내", message: "압축 실패한 파일이 있습니다. 삭제 후 다시 시도해주세요.")
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
            .bind(with: self) { owner, indexPath in
                guard owner.currentMediaItems.indices.contains(indexPath.item) else { return }
                let item = owner.currentMediaItems[indexPath.item]
                owner.presentPreview(item: item)
            }
            .disposed(by: disposeBag)
        
        contentTextView.rx.text.orEmpty
            .map { !$0.isEmpty }
            .bind(with: self) { owner, hasText in
                owner.contentPlaceholderLabel.isHidden = hasText
            }
            .disposed(by: disposeBag)
    }
    
    private func presentPreview(item: PostMediaItem) {
        let items = currentMediaItems
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        let vc = MediaPreviewPagerViewController(items: items, startIndex: index)
        present(vc, animated: true)
    }

    private static func makeSectionLabel(text: String) -> UILabel {
        let label = UILabel()
        label.font = .Pretendard.caption1
        label.textColor = GrayStyle.gray60.color
        label.text = text
        return label
    }

    private func updateSubmitButton(enabled: Bool) {
        var config = submitButton.configuration
        config?.baseBackgroundColor = Brand.deepTurquoise.color?.withAlphaComponent(enabled ? 1.0 : 0.45)
        config?.baseForegroundColor = GrayStyle.gray30.color
        submitButton.configuration = config
    }

    private func updateInputFocusState(_ view: UIView, isFocused: Bool) {
        view.layer.borderColor = (isFocused ? Brand.deepTurquoise.color : Brand.deepTurquoise.color?.withAlphaComponent(0.5))?.cgColor
        view.layer.borderWidth = isFocused ? 2.0 : 1.5
    }
}

private extension CommunityCreateViewController {
    func isVideoPath(_ path: String) -> Bool {
        let ext = (path as NSString).pathExtension.lowercased()
        return ["mp4", "mov", "avi", "mkv", "wmv", "webm"].contains(ext)
    }

    func makeRemoteMediaItem(path: String) -> PostMediaItem {
        return PostMediaItem(
            id: UUID(),
            data: nil,
            fileName: (path as NSString).lastPathComponent,
            mimeType: nil,
            thumbnail: UIImage(),
            isVideo: isVideoPath(path),
            isValid: true,
            remotePath: path
        )
    }

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
            isValid: true,
            remotePath: nil
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
            isValid: false,
            remotePath: nil
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

        guard let image = downsampledImage(from: data, maxDimension: 1600) ?? UIImage(data: data) else {
            return .failedCompression(makeInvalidItem(thumbnail: nil, isVideo: false))
        }

        let qualities: [CGFloat] = [0.8, 0.7, 0.6]
        for quality in qualities {
            if let jpgData = image.jpegData(compressionQuality: quality), jpgData.count <= maxSize {
                let jpgName = "post_media_\(UUID().uuidString).jpg"
                if let item = makeMediaItem(data: jpgData, fileName: jpgName, mimeType: "image/jpeg", fileExtension: "jpg", isVideo: false) {
                    return .success(item)
                }
            }
        }
        
        return .rejectedTooLarge(makeInvalidItem(thumbnail: image, isVideo: false))
    }

    func downsampledImage(from data: Data, maxDimension: CGFloat) -> UIImage? {
        let cfData = data as CFData
        guard let source = CGImageSourceCreateWithData(cfData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: Int(maxDimension)
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }
        return UIImage(cgImage: image)
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
            // 서버가 video/quicktime(mov)을 거부하는 경우가 있어 mp4만 즉시 허용
            if mime == "video/mp4", ext.lowercased() == "mp4" {
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
                    isValid: false,
                    remotePath: nil
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
                        isValid: false,
                        remotePath: nil
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

extension CommunityCreateViewController: UITextFieldDelegate, UITextViewDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        updateInputFocusState(textField, isFocused: true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateInputFocusState(textField, isFocused: false)
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        updateInputFocusState(textView, isFocused: true)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        updateInputFocusState(textView, isFocused: false)
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
