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
    var onComplete: ((Data, FilterImagePropsEntity) -> Void)?

    //MARK: - UI
    private let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()

    private let originalBadgeLabelBox: UIView = {
        let view = UIView()
        view.backgroundColor = Brand.blackTurquoise.color?.withAlphaComponent(0.5)
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
        view.isHidden = true
        return view
    }()
    
    private let originalBadgeLabel: UILabel = {
        let label = UILabel()
        label.text = "원본"
        label.textAlignment = .center
        label.font = .Pretendard.caption2
        label.textColor = GrayStyle.gray30.color
        return label
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

    private let filterSliderView = FilterSliderView()
    
    private let filterPropsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 12
        
        let spacing = 12.0
        let padding = 20.0
        let itemSize = (UIScreen.main.bounds
            .width - (2 * padding) - (4 * spacing)) / 5
        layout.itemSize = CGSize(width: itemSize, height: itemSize)
        
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view
            .register(
                FilterPropsCollectionViewCell.self,
                forCellWithReuseIdentifier: FilterPropsCollectionViewCell.identifier
            )
        view.backgroundColor = GrayStyle.gray100.color
        view.showsHorizontalScrollIndicator = false
        view.contentInset = UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20)
        return view
    }()

    init(viewModel: FilterEditViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    override var prefersCustomTabBarHidden: Bool { true }
    
    override func configureHierarchy() {
        view.addSubview(imageView)
        
        view.addSubview(originalBadgeLabelBox)
        originalBadgeLabelBox.addSubview(originalBadgeLabel)
        
        view.addSubview(rollbackStack)
        rollbackStack.addArrangedSubview(undoButton)
        rollbackStack.addArrangedSubview(redoButton)
        
        view.addSubview(compareButton)

        view.addSubview(filterSliderView)
        view.addSubview(filterPropsCollectionView)
    }

    override func configureLayout() {
        imageView.snp.makeConstraints { make in
            make.horizontalEdges.top.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalTo(filterSliderView.snp.top).offset(-20)
        }

        originalBadgeLabelBox.snp.makeConstraints { make in
            make.top.equalTo(imageView).inset(16)
            make.centerX.equalTo(imageView)
        }
        
        originalBadgeLabel.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(12)
            make.verticalEdges.equalToSuperview().inset(6)
        }
        
        rollbackStack.snp.makeConstraints { make in
            make.bottom.leading.equalTo(imageView).inset(20)
        }
        
        compareButton.snp.makeConstraints { make in
            make.bottom.trailing.equalTo(imageView).inset(20)
        }

        filterSliderView.snp.makeConstraints { make in
            make.bottom.equalTo(filterPropsCollectionView.snp.top).offset(-20)
            make.horizontalEdges.equalTo(view.safeAreaLayoutGuide).inset(20)
        }
        
        filterPropsCollectionView.snp.makeConstraints { make in
            make.horizontalEdges.bottom.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(80)
        }
    }

    override func configureView() {
        view.backgroundColor = GrayStyle.gray100.color
        navigationItem.title = "EDIT"
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "save"))
        navigationItem.rightBarButtonItem?.tintColor = GrayStyle.gray75.color
    }

    override func configureBind() {
        let input = FilterEditViewModel.Input(
            selectedProp: filterPropsCollectionView.rx
                .modelSelected(FilterPropItem.self),
            sliderValueChanged: filterSliderView.valueChanged
        )
        
        let output = viewModel.transform(input: input)
        
        output.imageData
            .compactMap { UIImage(data: $0) }
            .drive(imageView.rx.image)
            .disposed(by: disposeBag)
        
        output.filterProps
            .drive(
                filterPropsCollectionView.rx.items(
                    cellIdentifier: FilterPropsCollectionViewCell.identifier,
                    cellType: FilterPropsCollectionViewCell.self
                )){ _, item, cell in
                    cell.configure(item: item)
                }
            .disposed(by: disposeBag)

        output.sliderValue
            .drive(onNext: { [weak self] value in
                self?.filterSliderView.configureValue(value: value)
            })
            .disposed(by: disposeBag)
        
        navigationItem.rightBarButtonItem?.rx.tap
            .bind(with: self, onNext: { owner, _ in
                owner.onComplete?(owner.viewModel.latestImageData, owner.viewModel.latestProps)
                owner.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
    }
}
