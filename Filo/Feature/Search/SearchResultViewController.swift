//
//  SearchResultViewController.swift
//  Filo
//
//  Created by 이상민 on 2/7/26.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class SearchResultViewController: BaseViewController {
    private let searchBar: UISearchBar = {
        let bar = UISearchBar()
        bar.placeholder = "검색어를 입력하세요"
        bar.searchBarStyle = .minimal
        return bar
    }()
    
    private let searchBarLineView: UIView = {
        let view = UIView()
        view.backgroundColor = Brand.deepTurquoise.color
        return view
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
    
    private let viewModel: SearchResultViewModel
    private let disposeBag = DisposeBag()
    
    init(viewModel: SearchResultViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    override func configureHierarchy() {
        view.addSubview(searchBar)
        view.addSubview(searchBarLineView)
        view.addSubview(collectionView)
    }
    
    override func configureLayout() {
        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).inset(4)
            make.horizontalEdges.equalTo(view.safeAreaLayoutGuide).inset(12)
        }
        
        searchBarLineView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(1)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(searchBarLineView.snp.bottom).offset(4)
            make.horizontalEdges.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    override func configureView() {
        view.backgroundColor = GrayStyle.gray100.color
        navigationItem.title = "검색 결과"
    }
    
    override func configureBind() {
        let input = SearchResultViewModel.Input(
            searchText: searchBar.rx.text.orEmpty,
            searchSubmit: searchBar.rx.searchButtonClicked
        )
        
        let output = viewModel.transform(input: input)
        
        output.posts
            .drive(collectionView.rx.items(
                cellIdentifier: SearchPostCollectionViewCell.identifier,
                cellType: SearchPostCollectionViewCell.self
            )) { _, item, cell in
                cell.configure(item: item)
            }
            .disposed(by: disposeBag)
        
        output.networkError
            .emit(with: self) { owner, error in
                owner.showAlert(title: "오류", message: error.errorDescription)
            }
            .disposed(by: disposeBag)
        
        searchBar.rx.searchButtonClicked
            .bind(with: self) { owner, _ in
                owner.searchBar.resignFirstResponder()
            }
            .disposed(by: disposeBag)
    }
}

