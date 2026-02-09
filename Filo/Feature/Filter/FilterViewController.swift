//
//  FilterViewController.swift
//  Filo
//
//  Created by 이상민 on 12/17/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import PhotosUI
import UniformTypeIdentifiers

final class FilterViewController: BaseViewController {
    //MARK: - Properties
    private let disposeBag = DisposeBag()
    private let viewModel: FilterViewModel
    private var categoryDataSource: UICollectionViewDiffableDataSource<FilterCategorySection, FilterCategoryEntity>!
    private let imageSelectedRelay = PublishRelay<Data>()
    private let assetIdentifierRelay = PublishRelay<String?>()
    private let editResultRelay = PublishRelay<(Data, FilterImagePropsEntity)>()
    private var selectionToken: Int = 0
    private var pendingSelectionWorkItem: DispatchWorkItem?
    private var pendingOriginalData: Data?
    private var pendingAssetIdentifier: String?
    private let resetFormRelay = PublishRelay<Void>()
    
    init(viewModel: FilterViewModel = FilterViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    //MARK: - UI
    private let filterScrollView: UIScrollView = {
        let view = UIScrollView()
        view.showsVerticalScrollIndicator = false
        view.contentInset.bottom = CustomTabBarView.height
        view.verticalScrollIndicatorInsets.bottom = CustomTabBarView.height
        return view
    }()
    
    private let filterStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 20
        return view
    }()
    
    //필터명
    private let filterNameTitle = FilterTitleView(title: "필터명")
    private let filterNameTextField: InsetTextField = {
        let field = InsetTextField()
        field.placeholder = "필터 이름을 입력해주세요."
        return field
    }()
    private lazy var filterNameSection = FilterSectionView(titleView: filterNameTitle, contentView: filterNameTextField)
    
    //카테고리
    private let filterCategoryTitle = FilterTitleView(title: "카테고리")
    private lazy var filterCategoryCollectionView: UICollectionView = {
        let layout = makeCategoryLayout()
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.register(
            FilterCategoryCollectionViewCell.self,
            forCellWithReuseIdentifier: FilterCategoryCollectionViewCell.identifier
        )
        view.showsHorizontalScrollIndicator = false
        view.alwaysBounceVertical = false
        view.bounces = false
        return view
    }()
    private lazy var filterCategorySection = FilterSectionView(titleView: filterCategoryTitle, contentView: filterCategoryCollectionView)
    
    //대표 사진 등록
    private let filterImageRegisterView = FilterImageRegisterView()
    private let filterImageEditButton: UIButton = {
        var config = UIButton.Configuration.plain()
        var attributedTitle = AttributedString("수정하기")
        attributedTitle.font = .Pretendard.body1
        config.attributedTitle = attributedTitle
        config.contentInsets = .zero
        config.baseForegroundColor = GrayStyle.gray75.color
        
        let button = UIButton(configuration: config)
        button.isHidden = true
        return button
    }()
    private lazy var filterImageTitle = FilterTitleView(
        title: "대표 사진 등록",
        trailingView: filterImageEditButton
    )
    private lazy var filterImageRegisterSection = FilterSectionView(titleView: filterImageTitle, contentView: filterImageRegisterView)
    
    //필터 소개
    private let filterIntroduceTitle = FilterTitleView(title: "필터 소개")
    private let filterIntroduceTextField: InsetTextField = {
        let field = InsetTextField()
        field.placeholder = "이 필터에 대해 간단하게 소개해주세요."
        field.returnKeyType = .next
        return field
    }()
    private lazy var filterIntroduceSection = FilterSectionView(titleView: filterIntroduceTitle, contentView: filterIntroduceTextField)
    
    //판매 가격
    private let filterPriceTitle = FilterTitleView(title: "판매 가격")
    private let filterPriceTextField: InsetTextField = {
        let field = InsetTextField()
        field.placeholder = "1,000"
        field.keyboardType = .numberPad
        return field
    }()
    
    private let priceUnitLabel: UILabel = {
        let label = UILabel()
        label.text = "원"
        label.font = .Pretendard.body2
        label.textColor = GrayStyle.gray75.color
        return label
    }()
    
    private lazy var priceUnitView: UIView = {
        priceUnitLabel.sizeToFit()
        let height = max(priceUnitLabel.bounds.height, 24)
        let width = priceUnitLabel.bounds.width + 12
        let container = UIView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        priceUnitLabel.frame = CGRect(
            x: 0,
            y: (height - priceUnitLabel.bounds.height) / 2,
            width: priceUnitLabel.bounds.width,
            height: priceUnitLabel.bounds.height
        )
        container.addSubview(priceUnitLabel)
        return container
    }()
    
    private lazy var filterPriceSection = FilterSectionView(titleView: filterPriceTitle, contentView: filterPriceTextField)
    
    private lazy var filterViewTapGesture = UITapGestureRecognizer()
    
    override func configureHierarchy() {
        view.addSubview(filterScrollView)
        
        filterScrollView.addSubview(filterStackView)
        
        filterStackView.addArrangedSubview(filterNameSection)
        filterStackView.addArrangedSubview(filterCategorySection)
        filterStackView.addArrangedSubview(filterImageRegisterSection)
        filterStackView.addArrangedSubview(filterIntroduceSection)
        filterStackView.addArrangedSubview(filterPriceSection)
        
        view.addGestureRecognizer(filterViewTapGesture)
    }
    
    override func configureLayout() {
        filterScrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        filterStackView.snp.makeConstraints { make in
            make.horizontalEdges.equalTo(filterScrollView.frameLayoutGuide).inset(20)
            make.verticalEdges.equalTo(filterScrollView.contentLayoutGuide).inset(20)
        }
        
        filterCategoryCollectionView.snp.makeConstraints { make in
            make.height.equalTo(30)
        }
    }
    
    override func configureView() {
        navigationItem.title = viewModel.isEditMode ? "수정하기" : "MAKE"
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "save"))
        navigationItem.rightBarButtonItem?.tintColor = GrayStyle.gray75.color
        view.backgroundColor = .black
        filterViewTapGesture.cancelsTouchesInView = false
        
        filterPriceTextField.rightView = priceUnitView
        filterPriceTextField.rightViewMode = .always
        filterPriceTextField.contentInsets.right += priceUnitView.bounds.width
        
        configureCategoryDataSource()
        applyInitialFormIfNeeded()
    }
    
    override func configureBind() {
        let input = FilterViewModel.Input(
            categorySelected: filterCategoryCollectionView.rx.itemSelected
                .compactMap({ [weak self] indexPath in
                    self?.categoryDataSource
                        .itemIdentifier(for: indexPath)?.type
                }),
            imageSelected: imageSelectedRelay.asObservable(),
            editResult: editResultRelay.asObservable(),
            assetIdentifier: assetIdentifierRelay.asObservable(),
            resetForm: resetFormRelay.asObservable(),
            filterNameText: filterNameTextField.rx.text.orEmpty,
            filterIntroduceText: filterIntroduceTextField.rx.text.orEmpty,
            priceInputText: filterPriceTextField.rx.text.orEmpty,
            saveButtonTapped: navigationItem.rightBarButtonItem?
                .rx.tap
        )
        
        let output = viewModel.transform(input: input)
        
        output.categories
            .drive { [weak self] items in
                self?.applyCategorySnapshot(items)
            }
            .disposed(by: disposeBag)
        
        output.currentImageData
            .drive(onNext: { [weak self] data in
                guard let self else { return }
                guard let data, let image = UIImage(data: data) else {
                    self.filterImageRegisterView.reset()
                    return
                }
                self.filterImageRegisterView.setImage(image)
            })
            .disposed(by: disposeBag)

        output.metadata
            .drive(onNext: { [weak self] metadata in
                self?.filterImageRegisterView.applyMetadata(metadata)
            })
            .disposed(by: disposeBag)
        
        output.editEnabled
            .drive(filterImageEditButton.rx.isEnabled)
            .disposed(by: disposeBag)

        output.priceNumberText
            .drive(filterPriceTextField.rx.text)
            .disposed(by: disposeBag)

        output.saveEnabled
            .drive(with: self) { owner, isEnabled in
                owner.navigationItem.rightBarButtonItem?.isEnabled = isEnabled
                owner.navigationItem.rightBarButtonItem?.tintColor = isEnabled
                ? GrayStyle.gray75.color
                : GrayStyle.gray60.color?.withAlphaComponent(0.4)
            }
            .disposed(by: disposeBag)

        output.networkError
            .emit(onNext: { [weak self] error in
                self?.showAlert(title: "오류", message: error.errorDescription)
            })
            .disposed(by: disposeBag)
        
        output.saveSuccess
            .emit(with: self) { owner, _ in
                let message = owner.viewModel.isEditMode ? "필터가 수정되었습니다." : "필터가 등록되었습니다."
                owner.showAlert(title: "완료", message: message) { [weak owner] in
                    if owner?.viewModel.isEditMode == true {
                        owner?.navigationController?.popViewController(animated: true)
                    } else {
                        owner?.resetFormRelay.accept(())
                        owner?.resetFormUI()
                    }
                }
            }
            .disposed(by: disposeBag)

        filterNameTextField.rx.controlEvent(.editingDidEndOnExit)
            .bind(with: self) { owner, _ in
                owner.view.endEditing(true)
            }
            .disposed(by: disposeBag)

        filterIntroduceTextField.rx.controlEvent(.editingDidEndOnExit)
            .bind(with: self) { owner, _ in
                owner.filterPriceTextField.becomeFirstResponder()
            }
            .disposed(by: disposeBag)
        
        filterImageRegisterView.tap
            .subscribe(onNext: { [weak self] in
                self?.presentImagePicker()
            })
            .disposed(by: disposeBag)
        
        filterImageRegisterView.state
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] state in
                switch state {
                case .empty:
                    self?.filterImageTitle.setTrailingHidden(true)
                case .filled(_):
                    self?.filterImageTitle.setTrailingHidden(false)
                }
            })
            .disposed(by: disposeBag)
        
        filterImageEditButton.rx.tap
            .withLatestFrom(Observable.combineLatest(
                output.originalImageData.asObservable(),
                output.currentFilterProps.asObservable()
            ))
            .subscribe(onNext: { [weak self] imageData, filterProps in
                guard let self = self, let imageData else { return }
                self.pushEditViewController(with: imageData, props: filterProps, isNewSelection: false)
            })
            .disposed(by: disposeBag)
        
        filterViewTapGesture.rx.event
            .bind(with: self) { owner, _ in
                owner.view.endEditing(true)
            }
            .disposed(by: disposeBag)
    }
    
    private func applyInitialFormIfNeeded() {
        guard let seed = viewModel.initialSeed else { return }
        filterNameTextField.text = seed.title
        filterIntroduceTextField.text = seed.description
        filterPriceTextField.text = "\(seed.price)".formattedDecimal()
    }
    
    private func pushEditViewController(with imageData: Data, props: FilterImagePropsEntity?, isNewSelection: Bool) {
        let viewModel = FilterEditViewModel(imageData: imageData, initialProps: props)
        let editViewController = FilterEditViewController(viewModel: viewModel)
        editViewController.onComplete = { [weak self] data, props in
            guard let self else { return }
            if isNewSelection, let originalData = self.pendingOriginalData {
                self.imageSelectedRelay.accept(originalData)
                self.assetIdentifierRelay.accept(self.pendingAssetIdentifier)
                self.pendingOriginalData = nil
                self.pendingAssetIdentifier = nil
            }
            self.editResultRelay.accept((data, props))
        }
        navigationController?.pushViewController(editViewController, animated: true)
    }
    
    private func resetFormUI() {
        filterNameTextField.text = ""
        filterIntroduceTextField.text = ""
        filterPriceTextField.text = ""
        filterImageRegisterView.reset()
        filterCategoryCollectionView.reloadData()
    }
}

extension FilterViewController{
    private func makeCategoryLayout() -> UICollectionViewLayout{
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .estimated(50),
            heightDimension: .estimated(30)
        )
        
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .estimated(50),
            heightDimension: .absolute(30)
        )
        
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = 8
        section.contentInsets = .zero
        
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    private func configureCategoryDataSource(){
        categoryDataSource = UICollectionViewDiffableDataSource<FilterCategorySection, FilterCategoryEntity>(collectionView: filterCategoryCollectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: FilterCategoryCollectionViewCell.identifier,
                for: indexPath
            ) as? FilterCategoryCollectionViewCell else {
                return UICollectionViewCell()
            }
            
            cell.configure(itemIdentifier)
            return cell
        })
    }
    
    private func applyCategorySnapshot(_ items: [FilterCategoryEntity]){
        var snapshot = NSDiffableDataSourceSnapshot<FilterCategorySection, FilterCategoryEntity>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items)
        categoryDataSource.apply(snapshot)
    }
}

extension FilterViewController: PHPickerViewControllerDelegate{
    private func presentImagePicker(){
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.selectionLimit = 1
        configuration.filter = .images
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func picker(
        _ picker: PHPickerViewController,
        didFinishPicking results: [PHPickerResult]
    ) {
        picker.dismiss(animated: true)
        
        guard !results.isEmpty else { return }
        
        loadImage(from: results)
    }
    
    private func loadImage(from results: [PHPickerResult]){
        guard let result = results.first else { return }
        selectionToken += 1
        let currentToken = selectionToken
        let provider = result.itemProvider
        
        guard provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) else { return }
        
        provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { [weak self] data, _ in
            guard let data,
                  UIImage(data: data) != nil else { return }
            DispatchQueue.main.async {
                guard let self else { return }
                guard currentToken == self.selectionToken else { return }
                self.pendingSelectionWorkItem?.cancel()
                let workItem = DispatchWorkItem { [weak self] in
                    guard let self else { return }
                    guard currentToken == self.selectionToken else { return }
                    self.pendingOriginalData = data
                    self.pendingAssetIdentifier = result.assetIdentifier
                    self.pushEditViewController(with: data, props: nil, isNewSelection: true)
                }
                self.pendingSelectionWorkItem = workItem
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: workItem)
            }
        }
    }
}
