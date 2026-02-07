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
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("취소", for: .normal)
        button.titleLabel?.font = .Pretendard.body1
        button.setTitleColor(GrayStyle.gray30.color, for: .normal)
        button.isHidden = true
        return button
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

    private let resultsTableView: UITableView = {
        let view = UITableView()
        view.backgroundColor = .clear
        view.separatorStyle = .none
        view.showsVerticalScrollIndicator = false
        view.rowHeight = UITableView.automaticDimension
        view.register(SearchKeywordTableViewCell.self, forCellReuseIdentifier: SearchKeywordTableViewCell.identifier)
        view.register(SearchUserTableViewCell.self, forCellReuseIdentifier: SearchUserTableViewCell.identifier)
        return view
    }()
    
    let tap = UITapGestureRecognizer()

    // MARK: - Properties
    private let viewModel: SearchViewModel
    private let disposeBag = DisposeBag()
    private var didInvalidateCategoryLayout = false
    private var isSearchMode = false
    
    private var filterSectionHeightConstraint: Constraint?
    private var cancelButtonWidthConstraint: Constraint?
    private var searchBarTrailingToSafeConstraint: Constraint?
    private var searchBarTrailingToCancelConstraint: Constraint?

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
        view.addSubview(cancelButton)
        view.addSubview(filterSectionView)
        filterSectionView.addSubview(categoryCollectionView)
        filterSectionView.addSubview(orderButton)
        view.addSubview(collectionView)
        view.addSubview(resultsTableView)
    }

    override func configureLayout() {
        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).inset(8)
            make.leading.equalTo(view.safeAreaLayoutGuide).inset(12)
            searchBarTrailingToSafeConstraint = make.trailing.equalTo(view.safeAreaLayoutGuide).inset(12).constraint
            searchBarTrailingToCancelConstraint = make.trailing.equalTo(cancelButton.snp.leading).offset(-8).constraint
        }
        searchBarTrailingToCancelConstraint?.deactivate()
        
        cancelButton.snp.makeConstraints { make in
            make.centerY.equalTo(searchBar.snp.centerY)
            make.verticalEdges.equalTo(searchBar.searchTextField)
            make.trailing.equalTo(view.safeAreaLayoutGuide).inset(12)
            cancelButtonWidthConstraint = make.width.equalTo(0).constraint
        }
    
        filterSectionView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom).offset(8)
            make.horizontalEdges.equalTo(view.safeAreaLayoutGuide)
            filterSectionHeightConstraint = make.height.equalTo(36).constraint
        }

        categoryCollectionView.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview()
            make.leading.equalToSuperview().inset(12)
            make.trailing.equalTo(orderButton.snp.leading).offset(-20)
            make.height.equalTo(36)
        }

        orderButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(12)
            make.height.equalTo(24)
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(filterSectionView.snp.bottom).offset(8)
            make.horizontalEdges.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        resultsTableView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom)
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
        resultsTableView.alpha = 0
        resultsTableView.isHidden = true
        cancelButton.isHidden = true
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
        
        output.results
            .drive(resultsTableView.rx.items) { tableView, _, item in
                switch item {
                case .keyword(let text):
                    guard let cell = tableView.dequeueReusableCell(
                        withIdentifier: SearchKeywordTableViewCell.identifier
                    ) as? SearchKeywordTableViewCell else {
                        return UITableViewCell()
                    }
                    cell.configure(text: text)
                    return cell
                case .user(let user):
                    guard let cell = tableView.dequeueReusableCell(
                        withIdentifier: SearchUserTableViewCell.identifier
                    ) as? SearchUserTableViewCell else {
                        return UITableViewCell()
                    }
                    cell.configure(item: user)
                    return cell
                }
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

        searchBar.rx.textDidBeginEditing
            .bind(with: self) { owner, _ in
                owner.setSearchMode(true, animated: true)
            }
            .disposed(by: disposeBag)

        cancelButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.searchBar.text = ""
                owner.searchBar.resignFirstResponder()
                owner.setSearchMode(false, animated: true)
            }
            .disposed(by: disposeBag)
        
        searchBar.rx.searchButtonClicked
            .bind(with: self) { owner, _ in
                owner.searchBar.resignFirstResponder()
            }
            .disposed(by: disposeBag)

        resultsTableView.rx.modelSelected(SearchResultItem.self)
            .bind(with: self) { owner, item in
                switch item {
                case .keyword:
                    owner.searchBar.resignFirstResponder()
                case .user(let user):
                    let vm = UserProfileViewModel(userId: user.userID)
                    let vc = UserProfileViewController(viewModel: vm)
                    owner.navigationController?.pushViewController(vc, animated: true)
                }
            }
            .disposed(by: disposeBag)
    }
}

private extension SearchViewController {
    func setSearchMode(_ isActive: Bool, animated: Bool) {
        guard isSearchMode != isActive else { return }
        isSearchMode = isActive
        cancelButton.isHidden = false
        cancelButtonWidthConstraint?.update(offset: isActive ? 44 : 0)
        if isActive {
            searchBarTrailingToSafeConstraint?.deactivate()
            searchBarTrailingToCancelConstraint?.activate()
        } else {
            searchBarTrailingToCancelConstraint?.deactivate()
            searchBarTrailingToSafeConstraint?.activate()
        }
        resultsTableView.isHidden = false
        collectionView.isHidden = false
        
        let animations = {
            self.filterSectionHeightConstraint?.update(offset: isActive ? 0 : 36)
            self.filterSectionView.alpha = isActive ? 0 : 1
            self.collectionView.alpha = isActive ? 0 : 1
            self.resultsTableView.alpha = isActive ? 1 : 0
            self.resultsTableView.transform = isActive ? .identity : CGAffineTransform(translationX: 0, y: 8)
            self.view.layoutIfNeeded()
        }
        
        let completion: (Bool) -> Void = { _ in
            self.resultsTableView.isHidden = !isActive
            self.collectionView.isHidden = isActive
            self.cancelButton.isHidden = !isActive
        }
        
        if animated {
            UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseInOut]) {
                animations()
            } completion: { finished in
                completion(finished)
            }
        } else {
            animations()
            completion(true)
        }
    }
}
