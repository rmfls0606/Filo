//
//  LikedContentViewController.swift
//  Filo
//
//  Created by 이상민 on 2/8/26.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class LikedContentViewController: BaseViewController {
    private let viewModel: LikedContentViewModel
    private let disposeBag = DisposeBag()
    private let likeFilterRelay = PublishRelay<String>()
    private let likePostRelay = PublishRelay<PostSummaryResponseDTO>()
    
    private let filterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("필터", for: .normal)
        button.titleLabel?.font = .Pretendard.body1
        return button
    }()
    
    private let postButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("게시글", for: .normal)
        button.titleLabel?.font = .Pretendard.body1
        return button
    }()
    
    private let segmentStack: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.distribution = .fillEqually
        return view
    }()
    
    private let indicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = Brand.deepTurquoise.color
        return view
    }()
    
    private var indicatorLeadingConstraint: Constraint?
    
    private let filterCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 16, left: 20, bottom: 20, right: 20)
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .clear
        view.register(MyFilterCardCell.self, forCellWithReuseIdentifier: MyFilterCardCell.identifier)
        return view
    }()
    
    private let postCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 2
        layout.minimumLineSpacing = 2
        layout.sectionInset = UIEdgeInsets(top: 4, left: 2, bottom: 20, right: 2)
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .clear
        view.register(SearchPostCollectionViewCell.self, forCellWithReuseIdentifier: SearchPostCollectionViewCell.identifier)
        return view
    }()
    
    init(viewModel: LikedContentViewModel = LikedContentViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func configureView() {
        view.backgroundColor = GrayStyle.gray100.color
        navigationItem.title = "찜한 자료"
    }
    
    override func configureHierarchy() {
        view.addSubview(segmentStack)
        view.addSubview(indicatorView)
        view.addSubview(filterCollectionView)
        view.addSubview(postCollectionView)
        
        segmentStack.addArrangedSubview(filterButton)
        segmentStack.addArrangedSubview(postButton)
    }
    
    override func configureLayout() {
        segmentStack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).inset(8)
            make.horizontalEdges.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(40)
        }

        indicatorView.snp.makeConstraints { make in
            make.top.equalTo(segmentStack.snp.bottom)
            make.height.equalTo(2)
            make.width.equalTo(segmentStack.snp.width).multipliedBy(0.5)
            indicatorLeadingConstraint = make.leading.equalTo(segmentStack).constraint
        }
        
        filterCollectionView.snp.makeConstraints { make in
            make.top.equalTo(indicatorView.snp.bottom)
            make.horizontalEdges.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        
        postCollectionView.snp.makeConstraints { make in
            make.top.equalTo(indicatorView.snp.bottom)
            make.horizontalEdges.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let layout = filterCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            let insets = layout.sectionInset
            let totalSpacing = layout.minimumInteritemSpacing + insets.left + insets.right
            let availableWidth = filterCollectionView.bounds.width - totalSpacing
            let itemWidth = floor(availableWidth / 2)
            let itemHeight = itemWidth + 110
            layout.itemSize = CGSize(width: itemWidth, height: itemHeight)
        }
        
        if let layout = postCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            let insets = layout.sectionInset
            let totalSpacing = insets.left + insets.right + layout.minimumInteritemSpacing * 2
            let availableWidth = postCollectionView.bounds.width - totalSpacing
            let itemWidth = floor(availableWidth / 3)
            layout.itemSize = CGSize(width: itemWidth, height: itemWidth * 1.4)
        }
    }
    
    override func configureBind() {
        let input = LikedContentViewModel.Input(
            viewWillAppear: rx.methodInvoked(#selector(UIViewController.viewWillAppear(_:))).map { _ in },
            filterTabTapped: filterButton.rx.tap.asObservable(),
            postTabTapped: postButton.rx.tap.asObservable(),
            selectedFilter: filterCollectionView.rx.modelSelected(FilterSummaryResponseEntity.self).asObservable(),
            selectedPost: postCollectionView.rx.modelSelected(PostSummaryResponseDTO.self).asObservable(),
            likeFilterTap: likeFilterRelay.asObservable(),
            likePostTap: likePostRelay.asObservable()
        )
        
        let output = viewModel.transform(input: input)
        
        output.filters
            .drive(filterCollectionView.rx.items(
                cellIdentifier: MyFilterCardCell.identifier,
                cellType: MyFilterCardCell.self
            )) { [weak self] _, item, cell in
                guard let self else { return }
                let isLiked = LikeStore.shared.isLiked(id: item.filterId)
                cell.configure(item, isLiked: isLiked)
                cell.likeTapped
                    .throttle(.milliseconds(400), scheduler: MainScheduler.instance)
                    .map { item.filterId }
                    .bind(to: self.likeFilterRelay)
                    .disposed(by: cell.disposeBag)
            }
            .disposed(by: disposeBag)
        
        output.posts
            .drive(postCollectionView.rx.items(
                cellIdentifier: SearchPostCollectionViewCell.identifier,
                cellType: SearchPostCollectionViewCell.self
            )) { [weak self] _, item, cell in
                guard let self else { return }
                cell.configure(item: item, showLike: true)
                cell.likeTapped
                    .throttle(.milliseconds(400), scheduler: MainScheduler.instance)
                    .map { item }
                    .bind(to: self.likePostRelay)
                    .disposed(by: cell.disposeBag)
            }
            .disposed(by: disposeBag)
        
        output.selectedSegment
            .drive(with: self) { owner, index in
                owner.updateSegmentSelection(selectedIndex: index, animated: true)
            }
            .disposed(by: disposeBag)
        
        output.selectedFilterId
            .drive(with: self) { owner, filterId in
                let vm = DetailViewModel(filterId: filterId)
                let vc = DetailViewController(viewModel: vm)
                owner.navigationController?.pushViewController(vc, animated: true)
            }
            .disposed(by: disposeBag)
        
        output.selectedPostId
            .drive(with: self) { owner, postId in
                let vm = CommunityDetailViewModel(postId: postId)
                let vc = CommunityDetailViewController(viewModel: vm)
                owner.navigationController?.pushViewController(vc, animated: true)
            }
            .disposed(by: disposeBag)
        
        output.networkError
            .emit(with: self) { owner, error in
                owner.showAlert(title: "오류", message: error.errorDescription)
            }
            .disposed(by: disposeBag)
        
        updateSegmentSelection(selectedIndex: 0, animated: false)
    }
}

private extension LikedContentViewController {
    func updateSegmentSelection(selectedIndex: Int, animated: Bool) {
        let selectedColor = GrayStyle.gray30.color
        let normalColor = GrayStyle.gray75.color
        
        filterButton.setTitleColor(selectedIndex == 0 ? selectedColor : normalColor, for: .normal)
        postButton.setTitleColor(selectedIndex == 1 ? selectedColor : normalColor, for: .normal)
        
        filterCollectionView.isHidden = selectedIndex != 0
        postCollectionView.isHidden = selectedIndex != 1
        
        let target = selectedIndex == 0 ? filterButton : postButton
        indicatorLeadingConstraint?.deactivate()
        indicatorView.snp.makeConstraints { make in
            indicatorLeadingConstraint = make.leading.equalTo(target).constraint
        }
        
        if animated {
            UIView.animate(withDuration: 0.2) {
                self.view.layoutIfNeeded()
            }
        } else {
            view.layoutIfNeeded()
        }
    }
}
