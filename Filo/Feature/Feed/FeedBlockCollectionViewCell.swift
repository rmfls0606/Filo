//
//  FeedBlockCollectionViewCell.swift
//  Filo
//
//  Created by 이상민 on 01/23/26.
//

import UIKit
import SnapKit

final class FeedBlockCollectionViewCell: BaseCollectionViewCell {
    private var imageRatio: CGFloat = 1
    private let thumbnailImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.layer.cornerRadius = 12
        return view
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
    
    override func configureHierarchy() {
        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(nicknameLabel)
    }
    
    override func configureLayout() {
        thumbnailImageView.snp.makeConstraints { make in
            make.top.horizontalEdges.equalToSuperview()
            make.height.equalTo(thumbnailImageView.snp.width).multipliedBy(imageRatio)
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
    
    func configure(_ item: FilterSummaryResponseDTO, imageRatio: CGFloat = 1) {
        self.imageRatio = imageRatio
        thumbnailImageView.snp.remakeConstraints { make in
            make.top.horizontalEdges.equalToSuperview()
            make.height.equalTo(thumbnailImageView.snp.width).multipliedBy(imageRatio)
        }
        thumbnailImageView.setKFImage(urlString: item.files[1])
        titleLabel.text = item.title
        nicknameLabel.text = item.creator.nick
    }
    
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
}
