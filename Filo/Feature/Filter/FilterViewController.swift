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

final class FilterViewController: BaseViewController {
    //MARK: - Properties
    private let disposeBag = DisposeBag()
    private let viewModel = FilterViewModel()
    private var categoryDataSource: UICollectionViewDiffableDataSource<FilterCategorySection, FilterCategoryEntity>!
    
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
    
    override func configureHierarchy() {
        view.addSubview(filterScrollView)
        
        filterScrollView.addSubview(filterStackView)
        
        filterStackView.addArrangedSubview(filterNameSection)
        filterStackView.addArrangedSubview(filterCategorySection)
        filterStackView.addArrangedSubview(filterImageRegisterSection)
        filterStackView.addArrangedSubview(filterIntroduceSection)
        filterStackView.addArrangedSubview(filterPriceSection)
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
        navigationItem.title = "MAKE"
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "save"))
        navigationItem.rightBarButtonItem?.tintColor = GrayStyle.gray75.color
        view.backgroundColor = .black
        
        filterPriceTextField.rightView = priceUnitView
        filterPriceTextField.rightViewMode = .always
        filterPriceTextField.contentInsets.right += priceUnitView.bounds.width
        
        configureCategoryDataSource()
    }
    
    override func configureBind() {
        let input = FilterViewModel.Input(
            categorySelected: filterCategoryCollectionView.rx.itemSelected
                .compactMap({ [weak self] indexPath in
                    self?.categoryDataSource
                        .itemIdentifier(for: indexPath)?.type
                })
        )
        
        let output = viewModel.transform(input: input)
        
        output.categories
            .drive { [weak self] items in
                self?.applyCategorySnapshot(items)
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
        configuration.selectionLimit = 2
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
        
        loadImages(from: results)
    }
    
    private func loadImages(from results: [PHPickerResult]){
        var images: [UIImage] = []
        let group = DispatchGroup()
        
        for result in results{
            let provider = result.itemProvider
            
            guard provider.canLoadObject(ofClass: UIImage.self) else { continue }
            
            group.enter()
            provider.loadObject(ofClass: UIImage.self) { object, _ in
                defer { group.leave() }
                if let image = object as? UIImage{
                    images.append(image)
                }
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            guard let first = images.first else { return }
            self?.filterImageRegisterView.setImage(first)
        }
    }
}
