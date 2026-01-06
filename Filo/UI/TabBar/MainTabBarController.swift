//
//  MainTabBarController.swift
//  Filo
//
//  Created by 이상민 on 12/16/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class MainTabBarController: UITabBarController {

    //MARK: - Properties
    private let disposeBag = DisposeBag()
    private var isCustomTabBarHidden = false
    
    // MARK: - UI
    private let customTabBar = CustomTabBarView()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureViewControllers()
        configureTabBar()
        bind()
    }

    // MARK: - Setup
    private func configureViewControllers() {
        viewControllers = [
            UINavigationController(rootViewController: HomeViewController()),
            UINavigationController(rootViewController: FeedViewController()),
            UINavigationController(rootViewController: FilterViewController()),
            UINavigationController(rootViewController: SearchViewController()),
            UINavigationController(rootViewController: ProfileViewController())
        ]
    }

    private func configureTabBar() {
        tabBar.isHidden = true
        view.addSubview(customTabBar)

        customTabBar.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(CustomTabBarView.height)
        }
    }

    func setCustomTabBarHidden(_ hidden: Bool, animated: Bool = true) {
        guard hidden != isCustomTabBarHidden else { return }
        isCustomTabBarHidden = hidden

        customTabBar.isHidden = hidden
    }

    // MARK: - Bind
    private func bind() {
        customTabBar.selectedItem
            .subscribe(onNext: { [weak self] item in
                self?.selectedIndex = item.rawValue
            })
            .disposed(by: disposeBag)
    }
}
