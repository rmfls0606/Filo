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
    
    private let searchBarBottomLineView: UIView = {
        let view = UIView()
        view.backgroundColor = Brand.deepTurquoise.color
        return view
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
        layout.itemSize = CGSize(width: width, height: width * 1.2)
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
        view.showsHorizontalScrollIndicator = false
        view.alwaysBounceHorizontal = false
        view.isDirectionalLockEnabled = true
        view.rowHeight = 60
        view.register(SearchUserTableViewCell.self, forCellReuseIdentifier: SearchUserTableViewCell.identifier)
        view.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
        return view
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .large)
        view.hidesWhenStopped = true
        return view
    }()
    
    private let appendLoadingIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.hidesWhenStopped = true
        return view
    }()
    
    private let emptyBackgroundLabel: UILabel = {
        let label = UILabel()
        label.textColor = GrayStyle.gray30.color
        label.font = .Pretendard.body1
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    let tap = UITapGestureRecognizer()

    // MARK: - Properties
    private let viewModel: SearchViewModel
    private let initialQuery: String
    private let disposeBag = DisposeBag()
    private let refreshRelay = PublishRelay<Void>()
    private var didInvalidateCategoryLayout = false
    private var isSearchMode = false
    private var currentVideoIndex: IndexPath?
    private var currentPosts: [PostSummaryResponseDTO] = []
    private var selectedPostIndexPath: IndexPath?
    private var selectedPostIdForTransition: String?
    private var communityTransitionOriginFrame: CGRect?
    private weak var transitionSourceCell: SearchPostCollectionViewCell?
    
    private var filterSectionHeightConstraint: Constraint?
    private var cancelButtonWidthConstraint: Constraint?
    private var searchBarTrailingToSafeConstraint: Constraint?
    private var searchBarTrailingToCancelConstraint: Constraint?

    init(viewModel: SearchViewModel = SearchViewModel(), initialQuery: String = "") {
        self.viewModel = viewModel
        self.initialQuery = initialQuery.trimmingCharacters(in: .whitespacesAndNewlines)
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
        view.addSubview(searchBarBottomLineView)
        view.addSubview(cancelButton)
        view.addSubview(filterSectionView)
        filterSectionView.addSubview(categoryCollectionView)
        filterSectionView.addSubview(orderButton)
        view.addSubview(collectionView)
        view.addSubview(resultsTableView)
        view.addSubview(loadingIndicator)
        view.addSubview(appendLoadingIndicator)
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
        
        searchBarBottomLineView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom).offset(8)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(1)
        }
    
        filterSectionView.snp.makeConstraints { make in
            make.top.equalTo(searchBarBottomLineView.snp.bottom).offset(8)
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
            make.top.equalTo(searchBarBottomLineView.snp.bottom)
            make.horizontalEdges.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        
        loadingIndicator.snp.makeConstraints { make in
            make.center.equalTo(collectionView)
        }
        
        appendLoadingIndicator.snp.makeConstraints { make in
            make.centerX.equalTo(collectionView)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(12)
        }
    }

    override func configureView() {
        view.backgroundColor = GrayStyle.gray100.color
        navigationItem.title = "커뮤니티"
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: nil, action: nil)
        configureLeftNavigationItem()
        tap.delegate = self
        view.addGestureRecognizer(tap)
        tap.cancelsTouchesInView = false
        collectionView.delaysContentTouches = false
        orderButton.setContentHuggingPriority(.required, for: .horizontal)
        orderButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        resultsTableView.alpha = 0
        resultsTableView.isHidden = true
        cancelButton.isHidden = true
        if !initialQuery.isEmpty {
            searchBar.text = initialQuery
        }
    }

    override func configureBind() {
        collectionView.rx.setDelegate(self)
            .disposed(by: disposeBag)

        let input = SearchViewModel.Input(
            searchText: searchBar.rx.text.orEmpty.asObservable(),
            searchSubmit: searchBar.rx.searchButtonClicked.asObservable(),
            categorySelected: categoryCollectionView.rx.modelSelected(SearchCategoryItem.self),
            orderTapped: orderButton.rx.tap,
            refresh: refreshRelay.asObservable(),
            postSelected: collectionView.rx.modelSelected(PostSummaryResponseDTO.self),
            loadNextPage: collectionView.rx.prefetchItems
                .compactMap { [weak self] indexPaths -> Void? in
                    guard let self else { return nil }
                    guard let maxItem = indexPaths.map({ $0.item }).max() else { return nil }
                    let thresholdIndex = max(0, self.currentPosts.count - 10)
                    return maxItem >= thresholdIndex ? () : nil
                }
                .throttle(.milliseconds(300), scheduler: MainScheduler.instance),
            cancelLoadNextPage: collectionView.rx.cancelPrefetchingForItems
                .compactMap { [weak self] indexPaths -> Void? in
                    guard let self else { return nil }
                    guard let maxItem = indexPaths.map({ $0.item }).max() else { return nil }
                    let thresholdIndex = max(0, self.currentPosts.count - 10)
                    return maxItem >= thresholdIndex ? () : nil
                }
                .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
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
        
        output.posts
            .drive(with: self) { owner, posts in
                owner.currentPosts = posts
                if posts.isEmpty, !owner.initialQuery.isEmpty {
                    owner.emptyBackgroundLabel.text = "\"\(owner.initialQuery)\" 검색 결과가 존재하지 않습니다."
                    owner.collectionView.backgroundView = owner.emptyBackgroundLabel
                } else {
                    owner.collectionView.backgroundView = nil
                }
            }
            .disposed(by: disposeBag)
        
        output.posts
            .drive(with: self) { owner, _ in
                DispatchQueue.main.async {
                    owner.collectionView.layoutIfNeeded()
                    owner.updatePlayback()
                }
            }
            .disposed(by: disposeBag)
        
        output.results
            .drive(resultsTableView.rx.items) { tableView, _, item in
                switch item {
                case .keyword(let text):
                    guard let cell = tableView.dequeueReusableCell(
                        withIdentifier: SearchUserTableViewCell.identifier
                    ) as? SearchUserTableViewCell else {
                        return UITableViewCell()
                    }
                    cell.configureKeyword(text: text)
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
        
        output.isInitialLoading
            .drive(with: self) { owner, isLoading in
                if isLoading {
                    owner.loadingIndicator.startAnimating()
                } else {
                    owner.loadingIndicator.stopAnimating()
                }
            }
            .disposed(by: disposeBag)
        
        output.isAppendLoading
            .drive(with: self) { owner, isLoading in
                if isLoading {
                    owner.appendLoadingIndicator.startAnimating()
                } else {
                    owner.appendLoadingIndicator.stopAnimating()
                }
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

        navigationItem.rightBarButtonItem?.rx.tap
            .bind(with: self) { owner, _ in
                let vc = CommunityCreateViewController()
                vc.onCreated = { [weak owner] in
                    owner?.refreshRelay.accept(())
                }
                owner.navigationController?.pushViewController(vc, animated: true)
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
            .withLatestFrom(searchBar.rx.text.orEmpty)
            .bind(with: self) { owner, _ in
                let query = owner.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                guard !query.isEmpty else { return }
                owner.searchBar.resignFirstResponder()
                let vm = SearchViewModel(initialQuery: query)
                let vc = SearchViewController(viewModel: vm, initialQuery: query)
                owner.navigationController?.pushViewController(vc, animated: true)
            }
            .disposed(by: disposeBag)

        resultsTableView.rx.modelSelected(SearchResultItem.self)
            .bind(with: self) { owner, item in
                switch item {
                case .keyword(let text):
                    let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !query.isEmpty else { return }
                    owner.searchBar.resignFirstResponder()
                    let vm = SearchViewModel(initialQuery: query)
                    let vc = SearchViewController(viewModel: vm, initialQuery: query)
                    owner.navigationController?.pushViewController(vc, animated: true)
                case .user(let user):
                    Task {
                        let currentUserId = await TokenStorage.shared.userId() ?? ""
                        if currentUserId.isEmpty { return }
                        if user.userID == currentUserId {
                            let vc = ProfileViewController()
                            owner.navigationController?.pushViewController(vc, animated: true)
                        } else {
                            let vm = UserProfileViewModel(userId: user.userID)
                            let vc = UserProfileViewController(viewModel: vm)
                            owner.navigationController?.pushViewController(vc, animated: true)
                        }
                    }
                }
            }
            .disposed(by: disposeBag)
        
        collectionView.rx.willBeginDragging
            .bind(with: self) { owner, _ in
                owner.stopAllPlayback()
            }
            .disposed(by: disposeBag)
        
        collectionView.rx.didEndDecelerating
            .bind(with: self) { owner, _ in
                owner.updatePlayback()
            }
            .disposed(by: disposeBag)
        
        collectionView.rx.didEndDragging
            .filter { !$0 }
            .bind(with: self) { owner, _ in
                owner.updatePlayback()
            }
            .disposed(by: disposeBag)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configureLeftNavigationItem()
        navigationController?.delegate = self
        setSearchMode(false, animated: false)
        collectionView.allowsSelection = true
        collectionView.isUserInteractionEnabled = true
        resultsTableView.isHidden = true
        resultsTableView.isUserInteractionEnabled = false
        resultsTableView.alpha = 0
        collectionView.isHidden = false
        collectionView.alpha = 1
        collectionView.isUserInteractionEnabled = true
        view.bringSubviewToFront(collectionView)
        for cell in collectionView.visibleCells {
            (cell as? SearchPostCollectionViewCell)?.setTransitionContentHidden(false)
        }
        updatePlayback()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAllPlayback()
    }
}

    private extension SearchViewController {
    var isPushedFromAnotherScreen: Bool {
        guard let navigationController else { return false }
        return navigationController.viewControllers.first !== self
    }
    
    func configureLeftNavigationItem() {
        let video = UIBarButtonItem(
            image: UIImage(systemName: "play.rectangle"),
            style: .plain,
            target: self,
            action: #selector(handleVideoButtonTap)
        )
        
        if isPushedFromAnotherScreen {
            let back = UIBarButtonItem(
                image: UIImage(systemName: "chevron.left"),
                style: .plain,
                target: self,
                action: #selector(handleBackButtonTap)
            )
            navigationItem.leftBarButtonItems = [back, video]
        } else {
            navigationItem.leftBarButtonItems = [video]
        }
    }
    
    @objc
    func handleBackButtonTap() {
        guard isPushedFromAnotherScreen else { return }
        navigationController?.popViewController(animated: true)
    }
    
    @objc
    func handleVideoButtonTap() {
        let vc = VideoListViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func presentCommunityDetail(postId: String, selectedIndexPath: IndexPath) {
        guard let navigationController else { return }
        selectedPostIndexPath = selectedIndexPath
        prepareCommunityPushTransition(postId: postId)
        collectionView.deselectItem(at: selectedIndexPath, animated: false)
        let vm = CommunityDetailViewModel(postId: postId)
        let vc = CommunityDetailViewController(viewModel: vm, initialPostId: postId)
        vc.onDeleted = { [weak self] _ in
            self?.selectedPostIndexPath = nil
            self?.selectedPostIdForTransition = nil
            self?.refreshRelay.accept(())
        }
        vc.onUpdated = { [weak self] _ in
            self?.refreshRelay.accept(())
        }
        navigationController.pushViewController(vc, animated: true)
    }

    func prepareCommunityPushTransition(postId: String) {
        selectedPostIdForTransition = postId
        guard let itemIndex = currentPosts.firstIndex(where: { $0.postId == postId }) else {
            communityTransitionOriginFrame = nil
            transitionSourceCell = nil
            return
        }
        
        let indexPath = IndexPath(item: itemIndex, section: 0)
        selectedPostIndexPath = indexPath
        
        collectionView.layoutIfNeeded()
        if collectionView.cellForItem(at: indexPath) == nil {
            collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
            collectionView.layoutIfNeeded()
        }
        
        guard let cell = collectionView.cellForItem(at: indexPath) as? SearchPostCollectionViewCell,
              let navView = navigationController?.view else {
            communityTransitionOriginFrame = nil
            transitionSourceCell = nil
            return
        }
        
        transitionSourceCell = cell
        communityTransitionOriginFrame = cell.transitionContentFrame(in: navView)
    }
    
    func transitionDestinationCell(in navigationController: UINavigationController) -> SearchPostCollectionViewCell? {
        var targetIndexPath = selectedPostIndexPath
        if let selectedId = selectedPostIdForTransition,
           let itemIndex = currentPosts.firstIndex(where: { $0.postId == selectedId }) {
            targetIndexPath = IndexPath(item: itemIndex, section: 0)
            selectedPostIndexPath = targetIndexPath
        } else if selectedPostIdForTransition != nil {
            selectedPostIndexPath = nil
            targetIndexPath = nil
        }
        guard let indexPath = targetIndexPath else { return nil }
        guard indexPath.section == 0 else { return nil }
        let itemCount = collectionView.numberOfItems(inSection: 0)
        guard itemCount > 0, indexPath.item >= 0, indexPath.item < itemCount else { return nil }
        
        view.layoutIfNeeded()
        collectionView.layoutIfNeeded()
        
        if collectionView.cellForItem(at: indexPath) == nil {
            collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
            collectionView.layoutIfNeeded()
        }
        
        return collectionView.cellForItem(at: indexPath) as? SearchPostCollectionViewCell
    }
    
    func updatePlayback() {
        guard !collectionView.isHidden else { return }
        var hasVideo = false
        for cell in collectionView.visibleCells {
            guard let mediaCell = cell as? SearchPostCollectionViewCell else { continue }
            if mediaCell.isVideoCell() {
                hasVideo = true
                mediaCell.startPlayback()
            } else {
                mediaCell.stopPlayback()
            }
        }
        if !hasVideo {
            stopAllPlayback()
        }
    }
    
    func stopAllPlayback() {
        for cell in collectionView.visibleCells {
            if let mediaCell = cell as? SearchPostCollectionViewCell {
                mediaCell.stopPlayback()
            }
        }
    }
    
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
            self.resultsTableView.isUserInteractionEnabled = isActive
            self.collectionView.isHidden = isActive
            self.collectionView.isUserInteractionEnabled = !isActive
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

extension SearchViewController: UINavigationControllerDelegate {
    func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> (any UIViewControllerAnimatedTransitioning)? {
        switch operation {
        case .push:
            guard fromVC === self else { return nil }
            guard let detailVC = toVC as? CommunityDetailViewController else { return nil }
            guard let frame = communityTransitionOriginFrame else { return nil }
            guard let sourceCell = transitionSourceCell else { return nil }
            guard let snapshot = sourceCell.makeTransitionSnapshotView() else { return nil }

            communityTransitionOriginFrame = nil
            transitionSourceCell = nil
            return CommunityPushAnimator(
                sourceFrame: frame,
                snapshotView: snapshot,
                onStart: {
                    detailVC.setCommunityTransitionMediaHidden(true)
                },
                onCompletion: {
                    detailVC.setCommunityTransitionMediaHidden(false)
                }
            )

        case .pop:
            guard fromVC is CommunityDetailViewController else { return nil }
            guard toVC === self else { return nil }
            guard let destinationCell = transitionDestinationCell(in: navigationController) else { return nil }
            let destinationFrame = destinationCell.transitionContentFrame(in: navigationController.view)
            return CommunityPopAnimator(
                destinationFrame: destinationFrame
            )

        default:
            return nil
        }
    }
}

extension SearchViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard collectionView === self.collectionView else { return }
        guard currentPosts.indices.contains(indexPath.item) else { return }
        let postId = currentPosts[indexPath.item].postId
        presentCommunityDetail(postId: postId, selectedIndexPath: indexPath)
    }
}

extension SearchViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer === tap {
            if let touchedView = touch.view, touchedView.isDescendant(of: collectionView) {
                return false
            }
            if let touchedView = touch.view, touchedView.isDescendant(of: resultsTableView) {
                return false
            }
        }
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
}
