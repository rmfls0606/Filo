//
//  SearchViewController.swift
//  Filo
//
//  Created by 이상민 on 12/17/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class SearchViewController: BaseViewController {
    // MARK: - UI
    private let searchBar: UISearchBar = {
        let bar = UISearchBar()
        bar.placeholder = "검색어를 입력하세요"
        bar.searchBarStyle = .minimal
        return bar
    }()

    private let filterSectionView = UIView()

    private let categoryCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 8
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.showsHorizontalScrollIndicator = false
        view.allowsMultipleSelection = false
        view.backgroundColor = .clear
        view.register(FilterCategoryCollectionViewCell.self, forCellWithReuseIdentifier: FilterCategoryCollectionViewCell.identifier)
        return view
    }()

    private let orderButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .capsule
        config.baseBackgroundColor = Brand.deepTurquoise.color
        config.baseForegroundColor = GrayStyle.gray60.color
        config.title = "최신순"
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.Pretendard.body2
            return outgoing
        }
        let button = UIButton(configuration: config)
        return button
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 2
        layout.minimumLineSpacing = 2
        let width = (UIScreen.main.bounds.width - (2.0 * 2)) / 3
        layout.itemSize = CGSize(width: width, height: width * 1.4)
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .clear
        view.register(SearchPostCollectionViewCell.self, forCellWithReuseIdentifier: SearchPostCollectionViewCell.identifier)
        return view
    }()
    
    let tap = UITapGestureRecognizer()

    // MARK: - Properties
    private let viewModel: SearchViewModel
    private let disposeBag = DisposeBag()
    private var didInvalidateCategoryLayout = false

    init(viewModel: SearchViewModel = SearchViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !didInvalidateCategoryLayout else { return }
        didInvalidateCategoryLayout = true
        categoryCollectionView.collectionViewLayout.invalidateLayout()
        categoryCollectionView.layoutIfNeeded()
    }
    
    override func configureHierarchy() {
        view.addSubview(searchBar)
        view.addSubview(filterSectionView)
        filterSectionView.addSubview(categoryCollectionView)
        filterSectionView.addSubview(orderButton)
        view.addSubview(collectionView)
    }

    override func configureLayout() {
        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).inset(8)
            make.horizontalEdges.equalTo(view.safeAreaLayoutGuide)
        }
        
        filterSectionView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom)
            make.horizontalEdges.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(36)
        }

        categoryCollectionView.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview()
            make.leading.equalToSuperview()
            make.trailing.equalTo(orderButton.snp.leading).offset(-8)
            make.height.equalTo(36)
        }

        orderButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(categoryCollectionView.snp.trailing).offset(8)
            make.trailing.equalToSuperview().inset(16)
            make.height.equalTo(24)
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(filterSectionView.snp.bottom).offset(8)
            make.horizontalEdges.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }

    override func configureView() {
        view.backgroundColor = GrayStyle.gray100.color
        navigationItem.title = "검색"
        view.addGestureRecognizer(tap)
        tap.cancelsTouchesInView = false
        orderButton.setContentHuggingPriority(.required, for: .horizontal)
        orderButton.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    override func configureBind() {
        let input = SearchViewModel.Input(
            searchText: searchBar.rx.text.orEmpty.asObservable(),
            searchSubmit: searchBar.rx.searchButtonClicked.asObservable(),
            categorySelected: categoryCollectionView.rx.modelSelected(SearchCategoryItem.self),
            orderTapped: orderButton.rx.tap
        )

        let output = viewModel.transform(input: input)

        output.categories
            .drive(categoryCollectionView.rx.items(
                cellIdentifier: FilterCategoryCollectionViewCell.identifier,
                cellType: FilterCategoryCollectionViewCell.self
            )) { _, item, cell in
                cell.configure(title: item.type.rawValue, isSelected: item.isSelected)
            }
            .disposed(by: disposeBag)

        output.categories
            .drive(with: self) { owner, _ in
                DispatchQueue.main.async {
                    owner.categoryCollectionView.collectionViewLayout.invalidateLayout()
                    owner.categoryCollectionView.layoutIfNeeded()
                }
            }
            .disposed(by: disposeBag)

        output.posts
            .drive(collectionView.rx.items(
                cellIdentifier: SearchPostCollectionViewCell.identifier,
                cellType: SearchPostCollectionViewCell.self
            )) { _, item, cell in
                cell.configure(item: item)
            }
            .disposed(by: disposeBag)

        output.orderTitle
            .drive(with: self) { owner, title in
                owner.orderButton.configuration?.title = title
            }
            .disposed(by: disposeBag)

        output.networkError
            .emit(with: self) { owner, error in
                owner.showAlert(title: "오류", message: error.errorDescription)
            }
            .disposed(by: disposeBag)
        
        tap.rx.event
            .bind(with: self) { owner, _ in
                owner.view.endEditing(true)
            }
            .disposed(by: disposeBag)
    }
}
