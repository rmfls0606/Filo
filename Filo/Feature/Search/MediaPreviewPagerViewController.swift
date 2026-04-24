//
//  MediaPreviewPagerViewController.swift
//  Filo
//
//  Created by 이상민 on 2/7/26.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class MediaPreviewPagerViewController: UIPageViewController {
    private let items: [PostMediaItem]
    private let startIndex: Int
    private let disposeBag = DisposeBag()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .white
        return button
    }()
    
    init(items: [PostMediaItem], startIndex: Int) {
        self.items = items
        self.startIndex = max(0, min(startIndex, items.count - 1))
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal)
        modalPresentationStyle = .fullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        dataSource = self
        delegate = self
        
        view.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(12)
            make.trailing.equalToSuperview().inset(16)
            make.size.equalTo(28)
        }
        closeButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.dismiss(animated: true)
            }
            .disposed(by: disposeBag)
        
        if let vc = viewController(at: startIndex) {
            setViewControllers([vc], direction: .forward, animated: false)
        }
    }
    
    private func viewController(at index: Int) -> MediaPreviewItemViewController? {
        guard items.indices.contains(index) else { return nil }
        let vc = MediaPreviewItemViewController(item: items[index])
        vc.view.tag = index
        return vc
    }
    
}

extension MediaPreviewPagerViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore vc: UIViewController) -> UIViewController? {
        let index = vc.view.tag
        return viewController(at: index - 1)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter vc: UIViewController) -> UIViewController? {
        let index = vc.view.tag
        return viewController(at: index + 1)
    }
}
