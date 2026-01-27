//
//  HotTrendCollectionViewCell.swift
//  Filo
//
//  Created by 이상민 on 1/22/26.
//

import UIKit
import SnapKit
import RxSwift

final class HotTrendCollectionViewCell: BaseCollectionViewCell {
    private var disposeBag = DisposeBag()
    
    //MARK: - UI
    private let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .Mulggeol.caption1
        label.textColor = GrayStyle.gray30.color
        label.numberOfLines = 2
        return label
    }()
    
    private let likeStackView: UIStackView = {
        let view = UIStackView()
        view.spacing = 4
        view.axis = .horizontal
        return view
    }()
    
    private let likeIcon: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(named: "like_Fill")
        view.contentMode = .scaleAspectFit
        view.tintColor = GrayStyle.gray30.color
        return view
    }()
    
    private let likeCountText: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.caption1
        label.textColor = GrayStyle.gray30.color
        return label
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
    
    override func configureHierarchy() {
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(likeStackView)
        
        likeStackView.addArrangedSubview(likeIcon)
        likeStackView.addArrangedSubview(likeCountText)
    }
    
    override func configureLayout() {
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.horizontalEdges.equalTo(imageView).inset(8)
        }
        
        likeStackView.snp.makeConstraints { make in
            make.bottom.trailing.equalToSuperview().inset(8)
            make.height.equalTo(16)
        }
        
        likeIcon.snp.makeConstraints { make in
            make.size.equalTo(16)
        }
    }
    
    //MARK: - Function
    func configure(_ item: FilterSummaryResponseEntity) {
        imageView.setKFImage(urlString: item.files[1])
        titleLabel.text = item.title
        
        Observable
            .combineLatest(LikeStore.shared.likedIds, LikeStore.shared.likeCounts)
            .map { likedIds, counts -> (Bool, Int) in
                let liked = likedIds.contains(item.filterId)
                let count = counts[item.filterId] ?? item.likeCount
                return (liked, count)
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] liked, count in
                self?.likeIcon.image = UIImage(named: liked ? "like_Fill" : "like_Empty")
                self?.likeCountText.text = "\(count)"
            })
            .disposed(by: disposeBag)
    }
}
