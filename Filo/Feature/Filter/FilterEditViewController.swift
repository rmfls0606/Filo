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
    //MARK: - Properties
    private let disposeBag = DisposeBag()
    private let viewModel: FilterEditViewModel

    //MARK: - UI
    private let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        return view
    }()

    init(viewModel: FilterEditViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    override func configureHierarchy() {
        view.addSubview(imageView)
    }

    override func configureLayout() {
        imageView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }

    override func configureView() {
        view.backgroundColor = GrayStyle.gray100.color
        navigationItem.title = "EDIT"
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "save"))
        navigationItem.rightBarButtonItem?.tintColor = GrayStyle.gray75.color
    }

    override func configureBind() {
        let input = FilterEditViewModel.Input()
        
        let output = viewModel.transform(input: input)
        
        output.imageData
            .map { UIImage(data: $0) }
            .drive(imageView.rx.image)
            .disposed(by: disposeBag)
    }
}
