//
//  HotTrendCollectionViewCell.swift
//  Filo
//
//  Created by 이상민 on 1/22/26.
//

import UIKit
import SnapKit

final class HotTrendCollectionViewCell: BaseCollectionViewCell {
    //MARK: - UI
    private let imageView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = .orange
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .Mulggeol.caption1
        label.textColor = GrayStyle.gray30.color
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
        view.tintColor = GrayStyle.gray30.color
        return view
    }()
    
    private let likeCountText: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.caption1
        label.textColor = GrayStyle.gray30.color
        return label
    }()
    
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
            make.top.leading.equalToSuperview().inset(8)
        }
        
        likeStackView.snp.makeConstraints { make in
            make.bottom.trailing.equalToSuperview().inset(8)
        }
    }
}
