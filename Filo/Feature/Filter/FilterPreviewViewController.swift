//
//  FilterPreviewViewController.swift
//  Filo
//
//  Created by Codex on 2/11/26.
//

import UIKit
import Photos
import Toast
import SnapKit
import RxSwift
import RxCocoa

final class FilterPreviewViewController: BaseViewController, UIScrollViewDelegate {
    private let viewModel: FilterEditViewModel
    private let disposeBag = DisposeBag()
    private var isChromeHidden = false
    private let filterTitle: String
    private let authorName: String
    
    private let previewScrollView: UIScrollView = {
        let view = UIScrollView()
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        view.bouncesZoom = true
        view.minimumZoomScale = 1.0
        view.maximumZoomScale = 4.0
        return view
    }()
    
    private let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        return view
    }()
    
    private let watermarkContainer: UIView = {
        let view = UIView()
        view.backgroundColor = Brand.blackTurquoise.color?.withAlphaComponent(0.5)
        return view
    }()
    
    private let watermarkLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.font = .Mulggeol.body1
        label.textColor = GrayStyle.gray30.color
        return label
    }()
    
    private let authorNameLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.font = .Mulggeol.caption1
        label.textColor = GrayStyle.gray30.color
        return label
    }()
    
    private lazy var singleTap: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer()
        gesture.numberOfTapsRequired = 1
        gesture.require(toFail: doubleTap)
        return gesture
    }()
    
    private lazy var doubleTap: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer()
        gesture.numberOfTapsRequired = 2
        return gesture
    }()
    
    init(
        imageData: Data,
        filterProps: FilterImagePropsEntity,
        filterTitle: String,
        authorName: String
    ) {
        self.viewModel = FilterEditViewModel(imageData: imageData, initialProps: filterProps)
        self.filterTitle = filterTitle
        self.authorName = authorName
        super.init(nibName: nil, bundle: nil)
    }
    
    override var prefersCustomTabBarHidden: Bool { true }
    
    override func configureHierarchy() {
        view.addSubview(previewScrollView)
        previewScrollView.addSubview(imageView)
        imageView.addSubview(watermarkContainer)
        watermarkContainer.addSubview(watermarkLabel)
        watermarkContainer.addSubview(authorNameLabel)
        
        view.addGestureRecognizer(singleTap)
        view.addGestureRecognizer(doubleTap)
    }
    
    override func configureLayout() {
        previewScrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        watermarkContainer.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
        }
        
        watermarkLabel.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(8)
            make.top.equalToSuperview().inset(8)
        }
        
        authorNameLabel.snp.makeConstraints { make in
            make.top.equalTo(watermarkLabel.snp.bottom).offset(4)
            make.bottom.horizontalEdges.equalToSuperview().inset(8)
        }
    }
    
    override func configureView() {
        view.backgroundColor = GrayStyle.gray100.color
        navigationItem.title = "미리보기"
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "save"))
        navigationItem.rightBarButtonItem?.tintColor = GrayStyle.gray75.color
        watermarkLabel.text = "\(filterTitle)"
        authorNameLabel.text = "by \(authorName)"
        
        previewScrollView.delegate = self
    }
    
    override func configureBind() {
        viewModel.previewImageData()
            .compactMap { UIImage(data: $0) }
            .drive(onNext: { [weak self] image in
                guard let self else { return }
                self.imageView.image = image
                self.layoutPreviewImage(image)
            })
            .disposed(by: disposeBag)
        
        navigationItem.rightBarButtonItem?.rx.tap
            .bind(with: self) { owner, _ in
                owner.saveCurrentImageToPhotoLibrary()
            }
            .disposed(by: disposeBag)
        
        singleTap.rx.event
            .bind(with: self) { owner, _ in
                owner.toggleNavigationChrome()
            }
            .disposed(by: disposeBag)
        
        doubleTap.rx.event
            .bind(with: self) { owner, gesture in
                owner.toggleZoom(at: gesture.location(in: owner.imageView))
            }
            .disposed(by: disposeBag)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let image = imageView.image else { return }
        layoutPreviewImage(image)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isChromeHidden {
            navigationController?.navigationBar.alpha = 1.0
            navigationController?.navigationBar.isUserInteractionEnabled = true
            watermarkContainer.alpha = 1.0
            isChromeHidden = false
        }
    }
    
    private func toggleNavigationChrome() {
        isChromeHidden.toggle()
        let targetAlpha: CGFloat = isChromeHidden ? 0.0 : 1.0
        UIView.animate(withDuration: 0.2) { [weak self] in
            self?.navigationController?.navigationBar.alpha = targetAlpha
            self?.watermarkContainer.alpha = targetAlpha
        }
        navigationController?.navigationBar.isUserInteractionEnabled = !isChromeHidden
    }
    
    private func toggleZoom(at point: CGPoint) {
        if previewScrollView.zoomScale > previewScrollView.minimumZoomScale {
            previewScrollView.setZoomScale(previewScrollView.minimumZoomScale, animated: true)
            return
        }
        
        let targetScale = min(previewScrollView.maximumZoomScale, previewScrollView.minimumZoomScale * 2.0)
        let width = previewScrollView.bounds.width / targetScale
        let height = previewScrollView.bounds.height / targetScale
        let rect = CGRect(x: point.x - (width / 2.0), y: point.y - (height / 2.0), width: width, height: height)
        previewScrollView.zoom(to: rect, animated: true)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) * 0.5, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)
        imageView.center = CGPoint(
            x: (scrollView.contentSize.width * 0.5) + offsetX,
            y: (scrollView.contentSize.height * 0.5) + offsetY
        )
    }
    
    private func layoutPreviewImage(_ image: UIImage) {
        let bounds = previewScrollView.bounds
        guard bounds.width > 0, bounds.height > 0 else { return }
        
        previewScrollView.zoomScale = 1.0
        
        let imageSize = image.size
        guard imageSize.width > 0, imageSize.height > 0 else {
            imageView.frame = bounds
            previewScrollView.contentSize = bounds.size
            return
        }
        
        let scale = min(bounds.width / imageSize.width, bounds.height / imageSize.height)
        let fittedSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        imageView.frame = CGRect(
            x: (bounds.width - fittedSize.width) * 0.5,
            y: (bounds.height - fittedSize.height) * 0.5,
            width: fittedSize.width,
            height: fittedSize.height
        )
        previewScrollView.contentSize = bounds.size
    }
    
    private func saveCurrentImageToPhotoLibrary() {
        guard let image = UIImage(data: viewModel.latestImageData) ?? imageView.image else {
            view.makeToast("이미지를 불러오는데 실패했습니다.", duration: 1.2, position: .bottom)
            return
        }
        let renderedImage = makeWatermarkedImage(from: image)
        
        let saveBlock = {
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: renderedImage)
            }) { [weak self] success, _ in
                DispatchQueue.main.async {
                    guard let self else { return }
                    if success {
                        self.view.makeToast("사진을 저장했습니다.", duration: 1.2, position: .bottom)
                        self.navigationController?.popViewController(animated: true)
                    } else {
                        self.view.makeToast("사진을 저장하는데 실패했습니다.", duration: 1.2, position: .bottom)
                    }
                }
            }
        }
        
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        switch status {
        case .authorized, .limited:
            saveBlock()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] newStatus in
                if newStatus == .authorized || newStatus == .limited {
                    saveBlock()
                } else {
                    DispatchQueue.main.async {
                        self?.showAlert(title: "권한 요청", message: "앨범에 접근할 수 있는 권한을 허용해주세요.")
                    }
                }
            }
        default:
            showAlert(title: "권한 요청", message: "앨범에 접근할 수 있는 권한을 허용해주세요.")
        }
    }
    
    private func makeWatermarkedImage(from image: UIImage) -> UIImage {
        view.layoutIfNeeded()
        imageView.layoutIfNeeded()
        watermarkContainer.layoutIfNeeded()

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = image.scale
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)

        return renderer.image { _ in
            let rect = CGRect(origin: .zero, size: image.size)
            image.draw(in: rect)

            let imageBounds = imageView.bounds
            let watermarkFrame = watermarkContainer.frame
            guard imageBounds.width > 0, imageBounds.height > 0,
                  watermarkFrame.width > 0, watermarkFrame.height > 0 else { return }

            let scaleX = image.size.width / imageBounds.width
            let scaleY = image.size.height / imageBounds.height
            let targetRect = CGRect(
                x: watermarkFrame.minX * scaleX,
                y: watermarkFrame.minY * scaleY,
                width: watermarkFrame.width * scaleX,
                height: watermarkFrame.height * scaleY
            )

            guard let cgContext = UIGraphicsGetCurrentContext() else { return }
            cgContext.saveGState()
            cgContext.translateBy(x: targetRect.minX, y: targetRect.minY)
            cgContext.scaleBy(
                x: targetRect.width / watermarkFrame.width,
                y: targetRect.height / watermarkFrame.height
            )
            watermarkContainer.layer.render(in: cgContext)
            cgContext.restoreGState()
        }
    }
}
