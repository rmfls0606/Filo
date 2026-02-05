//
//  HomeBannerView.swift
//  Filo
//
//  Created by 이상민 on 01/23/26.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class HomeBannerView: BaseView {
    //MARK: - Properties
    private let disposeBag = DisposeBag()
    let bannerSelected = PublishRelay<BannerDTO>()

    //MARK: - UI
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = .zero
        let padding = 20.0
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width - (2 * padding), height: 100)

        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.isPagingEnabled = true
        view.showsHorizontalScrollIndicator = false
        view.contentInset = .zero
        view.contentInsetAdjustmentBehavior = .never
        view.register(HomeBannerCollectionViewCell.self, forCellWithReuseIdentifier: HomeBannerCollectionViewCell.identifier)
        view.backgroundColor = .clear
        return view
    }()
    
    private let pageLabelBox: UIView = {
        let view = UIView()
        view.backgroundColor = GrayStyle.gray60.color?.withAlphaComponent(0.5)
        view.layer.borderColor = GrayStyle.gray60.color?.cgColor
        view.layer.borderWidth = 1.0
        return view
    }()

    private let pageLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.caption2
        label.textColor = GrayStyle.gray45.color
        return label
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        pageLabelBox.layer.cornerRadius = pageLabelBox.bounds.height / 2
    }

    override func configureHierarchy() {
        addSubview(collectionView)
        addSubview(pageLabelBox)
        pageLabelBox.addSubview(pageLabel)
    }

    override func configureLayout() {
        collectionView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalToSuperview()
        }

        pageLabelBox.snp.makeConstraints { make in
            make.trailing.equalTo(collectionView).inset(16)
            make.bottom.equalTo(collectionView).inset(12)
        }
        
        pageLabel.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview().inset(6)
            make.horizontalEdges.equalToSuperview().inset(12)
        }
    }

    func bind(items: Driver<BannerListResponseEntity>) {
        let driverItems = items
            .map { $0.data }
            .distinctUntilChanged { $0.map(\.imageUrl) == $1.map(\.imageUrl) }
        
        driverItems
            .drive(collectionView.rx.items(
                cellIdentifier: HomeBannerCollectionViewCell.identifier,
                cellType: HomeBannerCollectionViewCell.self
            )) { _, item, cell in
                cell.configure(urlString: item.imageUrl)
            }
            .disposed(by: disposeBag)

        collectionView.rx.modelSelected(BannerDTO.self)
            .bind(to: bannerSelected)
            .disposed(by: disposeBag)

        let itemsCount = driverItems
            .map { $0.count }
            .asObservable()

        collectionView.rx.contentOffset
            .withLatestFrom(itemsCount) { offset, count in
                let width = max(self.collectionView.bounds.width, 1)
                let page = Int(round(offset.x / width))
                let maxPage = max(count - 1, 0)
                return max(0, min(page, maxPage))
            }
            .distinctUntilChanged()
            .map { page in page + 1 }
            .withLatestFrom(itemsCount) { current, total in
                "\(current)/\(max(total, 1))"
            }
            .bind(to: pageLabel.rx.text)
            .disposed(by: disposeBag)

        itemsCount
            .map { total in
                "1/\(max(total, 1))"
            }
            .bind(to: pageLabel.rx.text)
            .disposed(by: disposeBag)
    }

}
