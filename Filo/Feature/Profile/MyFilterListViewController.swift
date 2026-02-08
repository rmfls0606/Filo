//
//  MyFilterListViewController.swift
//  Filo
//
//  Created by 이상민 on 2/8/26.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class MyFilterListViewController: BaseViewController {
    private let viewModel: MyFilterListViewModel
    private let disposeBag = DisposeBag()
    private let likeFilterRelay = PublishRelay<String>()
    
    private let emptyBackgroundLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.caption1
        label.textColor = GrayStyle.gray60.color
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "내가 작성한 필터가 없습니다."
        return label
    }()
    
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 16, left: 20, bottom: 20, right: 20)
        
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.register(MyFilterCardCell.self, forCellWithReuseIdentifier: MyFilterCardCell.identifier)
        view.backgroundColor = .clear
        view.alwaysBounceVertical = true
        return view
    }()
    
    init(viewModel: MyFilterListViewModel = MyFilterListViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func configureView() {
        view.backgroundColor = GrayStyle.gray100.color
        navigationItem.title = "내가 작성한 필터"
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
        let totalSpacing = layout.minimumInteritemSpacing + insets.left + insets.right
        let availableWidth = collectionView.bounds.width - totalSpacing
        let itemWidth = floor(availableWidth / 2)
        let itemHeight = itemWidth + 110
        layout.itemSize = CGSize(width: itemWidth, height: itemHeight)
    }
    
    override func configureBind() {
        let input = MyFilterListViewModel.Input(
            viewWillAppear: rx.methodInvoked(#selector(UIViewController.viewWillAppear(_:))).map { _ in },
            selectedItem: collectionView.rx.modelSelected(FilterSummaryResponseEntity.self).asObservable(),
            likeFilterTap: likeFilterRelay.asObservable()
        )
        
        let output = viewModel.transform(input: input)
        
        output.filters
            .drive(collectionView.rx.items(
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
        
        output.filters
            .drive(with: self) { owner, items in
                owner.collectionView.backgroundView = items.isEmpty ? owner.emptyBackgroundLabel : nil
            }
            .disposed(by: disposeBag)
        
        output.selectedFilterId
            .drive(with: self) { owner, filterId in
                let vm = DetailViewModel(filterId: filterId)
                let vc = DetailViewController(viewModel: vm)
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
