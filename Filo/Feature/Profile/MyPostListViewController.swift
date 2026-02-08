//
//  MyPostListViewController.swift
//  Filo
//
//  Created by 이상민 on 2/8/26.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class MyPostListViewController: BaseViewController {
    private let viewModel: MyPostListViewModel
    private let disposeBag = DisposeBag()
    private let refreshRelay = PublishRelay<Void>()
    private let likePostRelay = PublishRelay<PostSummaryResponseDTO>()
    
    private let emptyBackgroundLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.caption1
        label.textColor = GrayStyle.gray60.color
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "내가 작성한 게시글이 없습니다."
        return label
    }()
    
    private let collectionView: UICollectionView = {
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
    
    init(viewModel: MyPostListViewModel = MyPostListViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func configureView() {
        view.backgroundColor = GrayStyle.gray100.color
        navigationItem.title = "내가 올린 게시글"
    }
    
    override func configureHierarchy() {
        view.addSubview(collectionView)
    }
    
    override func configureLayout() {
        collectionView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        let insets = layout.sectionInset
        let totalSpacing = insets.left + insets.right + layout.minimumInteritemSpacing * 2
        let availableWidth = collectionView.bounds.width - totalSpacing
        let itemWidth = floor(availableWidth / 3)
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth * 1.4)
    }
    
    override func configureBind() {
        let input = MyPostListViewModel.Input(
            viewWillAppear: rx.methodInvoked(#selector(UIViewController.viewWillAppear(_:))).map { _ in },
            refresh: refreshRelay.asObservable(),
            selectedItem: collectionView.rx.modelSelected(PostSummaryResponseDTO.self).asObservable(),
            likePostTap: likePostRelay.asObservable()
        )
        
        let output = viewModel.transform(input: input)
        
        output.posts
            .drive(collectionView.rx.items(
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
        
        output.posts
            .drive(with: self) { owner, items in
                owner.collectionView.backgroundView = items.isEmpty ? owner.emptyBackgroundLabel : nil
            }
            .disposed(by: disposeBag)
        
        output.selectedPostId
            .drive(with: self) { owner, postId in
                let vm = CommunityDetailViewModel(postId: postId)
                let vc = CommunityDetailViewController(viewModel: vm)
                vc.onDeleted = { [weak owner] _ in
                    owner?.refreshRelay.accept(())
                }
                vc.onUpdated = { [weak owner] _ in
                    owner?.refreshRelay.accept(())
                }
                owner.navigationController?.pushViewController(vc, animated: true)
            }
            .disposed(by: disposeBag)
        
        output.networkError
            .emit(with: self) { owner, error in
                owner.showAlert(title: "오류", message: error.errorDescription)
            }
            .disposed(by: disposeBag)
    }
}
