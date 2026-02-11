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
    
    init(imageData: Data, filterProps: FilterImagePropsEntity) {
        self.viewModel = FilterEditViewModel(imageData: imageData, initialProps: filterProps)
        super.init(nibName: nil, bundle: nil)
    }

    override var prefersCustomTabBarHidden: Bool { true }

    override func configureHierarchy() {
        view.addSubview(previewScrollView)
        previewScrollView.addSubview(imageView)
        
        view.addGestureRecognizer(singleTap)
        view.addGestureRecognizer(doubleTap)
    }

    override func configureLayout() {
        previewScrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }

    override func configureView() {
        view.backgroundColor = GrayStyle.gray100.color
        navigationItem.title = "미리보기"
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "save"))
        navigationItem.rightBarButtonItem?.tintColor = GrayStyle.gray75.color

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
            isChromeHidden = false
        }
    }

    private func toggleNavigationChrome() {
        isChromeHidden.toggle()
        let targetAlpha: CGFloat = isChromeHidden ? 0.0 : 1.0
        UIView.animate(withDuration: 0.2) { [weak self] in
            self?.navigationController?.navigationBar.alpha = targetAlpha
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

        let saveBlock = {
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { [weak self] success, _ in
                DispatchQueue.main.async {
                    guard let self else { return }
                    if success {
                        self.view.makeToast("사진을 저장했습니다.", duration: 1.2, position: .bottom)
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
            showAlert(title: "권한ㅋ", message: "앨범에 접근할 수 있는 권한을 허용해주세요.")
        }
    }
}
