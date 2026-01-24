//
//  FeedBlockCollectionViewCell.swift
//  Filo
//
//  Created by 이상민 on 01/23/26.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class FeedBlockCollectionViewCell: BaseCollectionViewCell {
    private(set) var disposeBag = DisposeBag()
    
    var likeTapped: ControlEvent<Void>{
        likeButton.rx.tap
    }
    
    private var imageRatio: CGFloat = 1
    
    private let thumbnailImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let likeStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.spacing = 2
        return view
    }()
    
    private let likeButton = LikeButton()
    
    private let likeCountText: UILabel = {
        let label = UILabel()
        label.text = "0"
        label.font = .Pretendard.caption1
        label.textColor = GrayStyle.gray30.color
        return label
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .Mulggeol.caption1
        label.textColor = GrayStyle.gray30.color
        label.numberOfLines = 2
        return label
    }()
    
    private let nicknameLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.caption1
        label.textColor = GrayStyle.gray90.color
        return label
    }()
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        layoutIfNeeded()
        let targetSize = CGSize(width: layoutAttributes.size.width, height: UIView.layoutFittingCompressedSize.height)
        let size = contentView.systemLayoutSizeFitting(targetSize,
                                                       withHorizontalFittingPriority: .required,
                                                       verticalFittingPriority: .fittingSizeLevel)
        let attributes = layoutAttributes
        attributes.size.height = size.height
        return attributes
    }
    
    override func configureHierarchy() {
        contentView.addSubview(thumbnailImageView)
        
        contentView.addSubview(likeStackView)
        likeStackView.addArrangedSubview(likeButton)
        likeStackView.addArrangedSubview(likeCountText)
        
        contentView.addSubview(titleLabel)
        
        contentView.addSubview(nicknameLabel)
    }
    
    override func configureLayout() {
        thumbnailImageView.snp.makeConstraints { make in
            make.top.horizontalEdges.equalToSuperview()
            make.height.equalTo(thumbnailImageView.snp.width).multipliedBy(imageRatio)
        }
        
        likeStackView.snp.makeConstraints { make in
            make.bottom.trailing.equalTo(thumbnailImageView).inset(8)
            make.leading.greaterThanOrEqualTo(thumbnailImageView.snp.leading).offset(8)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.horizontalEdges.equalTo(thumbnailImageView).inset(8)
        }
        
        nicknameLabel.snp.makeConstraints { make in
            make.top.equalTo(thumbnailImageView.snp.bottom).offset(8)
            make.horizontalEdges.equalToSuperview().inset(8)
            make.bottom.equalToSuperview()
        }
    }
    
    override func configureView() {
        contentView.backgroundColor = .clear
    }
    
    func configure(_ item: FilterSummaryResponseEntity, imageRatio: CGFloat = 1) {
        self.imageRatio = imageRatio
        thumbnailImageView.snp.remakeConstraints { make in
            make.top.horizontalEdges.equalToSuperview()
            make.height.equalTo(thumbnailImageView.snp.width).multipliedBy(imageRatio)
        }
        setLiked(item.isLiked, item.likeCount)
        thumbnailImageView.setKFImage(urlString: item.files[1])
        titleLabel.text = item.title
        nicknameLabel.text = item.creator.nick
    }
    
    func setLiked(_ isLiked: Bool, _ likeCount: Int) {
        likeButton.isSelected = isLiked
        likeCountText.text = "\(likeCount)"
    }
}
