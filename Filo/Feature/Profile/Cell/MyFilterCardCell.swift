//
//  MyFilterCardCell.swift
//  Filo
//
//  Created by 이상민 on 2/8/26.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

private final class PaddingLabel: UILabel {
    var textInsets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
    
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textInsets))
    }
    
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + textInsets.left + textInsets.right,
                      height: size.height + textInsets.top + textInsets.bottom)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
        clipsToBounds = true
    }
}

final class MyFilterCardCell: BaseCollectionViewCell {
    private(set) var disposeBag = DisposeBag()
    
    var likeTapped: ControlEvent<Void> {
        likeButton.rx.tap
    }
    
    private let thumbnailImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.layer.cornerRadius = 12
        view.backgroundColor = GrayStyle.gray90.color
        return view
    }()

    private let likeButton = LikeButton()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.body2
        label.textColor = GrayStyle.gray30.color
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()
    
    private let categoryBadge: PaddingLabel = {
        let label = PaddingLabel()
        label.font = .Pretendard.caption2
        label.textColor = GrayStyle.gray60.color
        label.textAlignment = .center
        label.backgroundColor = Brand.blackTurquoise.color
        label.clipsToBounds = true
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.caption1
        label.textColor = GrayStyle.gray60.color
        label.numberOfLines = 2
        return label
    }()
    
    private let statsLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.caption2
        label.textColor = GrayStyle.gray60.color
        return label
    }()
    
    private let contentStack: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.alignment = .leading
        view.spacing = 6
        return view
    }()
    
    override func configureHierarchy() {
        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(likeButton)
        contentView.addSubview(contentStack)
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(categoryBadge)
        contentStack.addArrangedSubview(descriptionLabel)
        contentStack.addArrangedSubview(statsLabel)
    }
    
    override func configureLayout() {
        thumbnailImageView.snp.makeConstraints { make in
            make.top.horizontalEdges.equalToSuperview()
            make.height.equalTo(thumbnailImageView.snp.width).multipliedBy(1.0)
        }
        
        likeButton.snp.makeConstraints { make in
            make.trailing.equalTo(thumbnailImageView).inset(6)
            make.bottom.equalTo(thumbnailImageView).inset(6)
        }
        
        contentStack.snp.makeConstraints { make in
            make.top.equalTo(thumbnailImageView.snp.bottom).offset(10)
            make.horizontalEdges.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }
        
        categoryBadge.snp.makeConstraints { make in
            make.height.equalTo(22)
        }
    }
    
    override func configureView() {
        contentView.backgroundColor = .clear
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
        likeButton.isSelected = false
    }
    
    func configure(_ item: FilterSummaryResponseEntity, isLiked: Bool) {
        if item.files.indices.contains(1) {
            thumbnailImageView.setKFImage(urlString: item.files[1], targetSize: thumbnailImageView.bounds.size)
        } else if let first = item.files.first {
            thumbnailImageView.setKFImage(urlString: first, targetSize: thumbnailImageView.bounds.size)
        } else {
            thumbnailImageView.image = nil
        }
        titleLabel.text = item.title
        if let category = item.category, !category.isEmpty {
            categoryBadge.text = "#\(category)"
            categoryBadge.isHidden = false
        } else {
            categoryBadge.isHidden = true
        }
        descriptionLabel.text = item.description
        let initialCount = LikeStore.shared.likeCount(id: item.filterId) ?? item.likeCount
        setLiked(isLiked, likeCount: initialCount, buyerCount: item.buyerCount)
        
        Observable
            .combineLatest(LikeStore.shared.likedIds, LikeStore.shared.likeCounts)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] likedIds, counts in
                guard let self else { return }
                let liked = likedIds.contains(item.filterId)
                let count = counts[item.filterId] ?? item.likeCount
                self.setLiked(liked, likeCount: count, buyerCount: item.buyerCount)
            })
            .disposed(by: disposeBag)
    }
    
    private func setLiked(_ isLiked: Bool, likeCount: Int, buyerCount: Int) {
        likeButton.isSelected = isLiked
        statsLabel.text = "좋아요 \(likeCount) · 구매 \(buyerCount)"
    }
}
