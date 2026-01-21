//
//  HotTrendView.swift
//  Filo
//
//  Created by 이상민 on 1/22/26.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class HotTrendView: BaseView {
    //MARK: - Properties
    private let disposeBag = DisposeBag()
    private let dummyItems = Observable.just(["소낙씨", "화양연화", "여름밤", "도시감성"])
    
    //MARK: - UI
    private let hotTrendTitle: UILabel = {
        let label = UILabel()
        label.text = "핫 트렌드"
        label.textColor = GrayStyle.gray60.color
        label.font = .Pretendard.body1
        return label
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 8
        let spacing = 12.0
        let padding = 20
        let width = (UIScreen.main.bounds.width - spacing) / 1.8
        let height = width * 1.2
        layout.itemSize = CGSize(width: width, height: height)
    
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.register(HotTrendCollectionViewCell.self, forCellWithReuseIdentifier: HotTrendCollectionViewCell.identifier)
        view.showsHorizontalScrollIndicator = false
        view.contentInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        return view
    }()
    
    override func configureHierarchy() {
        addSubview(hotTrendTitle)
        addSubview(collectionView)
    }
    
    override func configureLayout() {
        hotTrendTitle.snp.makeConstraints { make in
            make.top.horizontalEdges.equalToSuperview().inset(20)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(hotTrendTitle.snp.bottom).offset(20)
            make.horizontalEdges.bottom.equalToSuperview()
        }
    }
    
    override func configureBind() {
        dummyItems
            .bind(to: collectionView.rx.items(
                cellIdentifier: HotTrendCollectionViewCell.identifier,
                cellType: HotTrendCollectionViewCell.self)
            ){ index, item, cell in
            }
            .disposed(by: disposeBag)
    }
}
