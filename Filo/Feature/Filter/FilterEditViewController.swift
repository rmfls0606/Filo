//
//  FilterEditViewController.swift
//  Filo
//
//  Created by 이상민 on 12/20/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class FilterEditViewController: BaseViewController {
    override func configureHierarchy() {}

    override func configureLayout() {}

    override func configureView() {
        view.backgroundColor = GrayStyle.gray100.color
        navigationItem.title = "EDIT"
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "save"))
        navigationItem.rightBarButtonItem?.tintColor = GrayStyle.gray75.color
    }

    override func configureBind() {}
}
