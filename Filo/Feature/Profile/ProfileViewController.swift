//
//  ProfileViewController.swift
//  Filo
//
//  Created by 이상민 on 12/17/25.
//

import UIKit
import RxSwift
import RxCocoa

final class ProfileViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    
    override func configureView() {
        navigationItem.title = "PROFILE"
        navigationItem.rightBarButtonItem?.tintColor = GrayStyle.gray75.color
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "message"))
    }

    override func configureBind() {
        navigationItem.rightBarButtonItem?.rx.tap
            .compactMap{ $0 }
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                let currentUserId = (try? KeychainManager.shared.read(key: .userId)) ?? ""
                let vm = ChatRoomListViewModel(currentUserId: currentUserId)
                let vc = ChatRoomListViewController(viewModel: vm)
                self.navigationController?.pushViewController(vc, animated: true)
            })
            .disposed(by: disposeBag)
    }
}
