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
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()
    
    private let rollbackStack: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.spacing = 8
        return view
    }()
    
    private let undoButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.baseForegroundColor = GrayStyle.gray60.color
        config.makeFilterResizeImageConfigurationFill(imageName: "undo")
        let button = UIButton(configuration: config)
        return button
    }()
    
    private let redoButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.baseForegroundColor = GrayStyle.gray75.color
        config.makeFilterResizeImageConfigurationFill(imageName: "redo")
        let button = UIButton(configuration: config)
        return button
    }()
    
    private let compareButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.baseForegroundColor = GrayStyle.gray60.color
        config.makeFilterResizeImageConfigurationFill(imageName: "compare")
        let button = UIButton(configuration: config)
        return button
    }()

    init(viewModel: FilterEditViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    override func configureHierarchy() {
        view.addSubview(imageView)
        
        view.addSubview(rollbackStack)
        rollbackStack.addArrangedSubview(undoButton)
        rollbackStack.addArrangedSubview(redoButton)
        
        view.addSubview(compareButton)
    }

    override func configureLayout() {
        imageView.snp.makeConstraints { make in
            make.horizontalEdges.top.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(400)
        }
        
        rollbackStack.snp.makeConstraints { make in
            make.bottom.leading.equalTo(imageView).inset(20)
        }
        
        compareButton.snp.makeConstraints { make in
            make.bottom.trailing.equalTo(imageView).inset(20)
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
