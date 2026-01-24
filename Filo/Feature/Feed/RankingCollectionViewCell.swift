//
//  RankingCollectionViewCell.swift
//  Filo
//
//  Created by 이상민 on 01/23/26.
//

import UIKit
import SnapKit

final class RankingCollectionViewCell: BaseCollectionViewCell {
    private let capsuleView: UIView = {
        let view = UIView()
        view.backgroundColor = Brand.blackTurquoise.color
        return view
    }()
    
    private let container: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()

    private let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()

    private let filterInfoStackView: UIStackView = {
        let view = UIStackView()
        view.spacing = 8
        view.axis = .vertical
        return view
    }()
    
    private let nicknameLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.caption1
        label.textColor = GrayStyle.gray75.color
        label.textAlignment = .center
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .Mulggeol.title1
        label.textColor = GrayStyle.gray30.color
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()

    private let categoryLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.body2
        label.textColor = GrayStyle.gray75.color
        label.textAlignment = .center
        return label
    }()

    private let rankBadge: UIView = {
        let view = UIView()
        view.backgroundColor = Brand.blackTurquoise.color
        view.clipsToBounds = true
        view.layer.borderWidth = 2.0
        view.layer.borderColor = Brand.deepTurquoise.color?.cgColor
        return view
    }()
    
    private let rankLabel: UILabel = {
        let label = UILabel()
        label.font = .Mulggeol.title1
        label.textAlignment = .center
        label.textColor = Brand.brightTurquoise.color
        return label
    }()

    override func layoutSubviews() {
        super.layoutSubviews()
        container.layoutIfNeeded()
        rankBadge.layoutIfNeeded()
        capsuleView.layer.cornerRadius = contentView.bounds.width / 2
        container.layer.cornerRadius = container.bounds.width / 2
        imageView.layer.cornerRadius = imageView.bounds.width / 2
        rankBadge.layer.cornerRadius = rankBadge.bounds.height / 2
    }

    override func configureHierarchy() {
        contentView.addSubview(capsuleView)
        capsuleView.addSubview(container)
        container.addSubview(imageView)
        container.addSubview(filterInfoStackView)
        filterInfoStackView.addArrangedSubview(nicknameLabel)
        filterInfoStackView.addArrangedSubview(titleLabel)
        filterInfoStackView.addArrangedSubview(categoryLabel)
        contentView.addSubview(rankBadge)
        rankBadge.addSubview(rankLabel)
    }

    override func configureLayout() {
        capsuleView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }

        imageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(imageView.snp.width)
        }

        filterInfoStackView.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(20)
            make.horizontalEdges.equalToSuperview().inset(8)
            make.bottom.lessThanOrEqualToSuperview().inset(-8)
        }

        rankBadge.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.size.equalTo(rankBadge.snp.height)
            make.centerY.equalTo(capsuleView.snp.bottom)
        }
        
        rankLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }
    }
    
    func configure(rank: Int, _ item: FilterSummaryResponseEntity) {
        imageView.setKFImage(urlString: item.files[1])
        nicknameLabel.text = item.creator.nick
        titleLabel.text = item.title
        if let category = item.category{
            categoryLabel.text = "#\(category)"
        }
        rankLabel.text = "\(rank)"
    }
}
