//
//  ProfileMenuCell.swift
//  Filo
//
//  Created by 이상민 on 2/8/26.
//

import UIKit
import SnapKit

final class ProfileMenuCell: BaseCollectionViewCell {
    struct Item {
        let title: String
        let iconName: String
    }
    
    private let contentStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 8
        return view
    }()

    private let iconView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.tintColor = GrayStyle.gray60.color
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.caption2
        label.textColor = GrayStyle.gray60.color
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = Brand.deepTurquoise.color
        view.layer.cornerRadius = 12
        return view
    }()

    override func configureHierarchy() {
        contentView.addSubview(containerView)
        containerView.addSubview(contentStackView)
        contentStackView.addArrangedSubview(iconView)
        contentStackView.addArrangedSubview(titleLabel)
    }

    override func configureLayout() {
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        contentStackView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
        }

        iconView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.size.equalTo(22)
        }

        titleLabel.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
        }
    }

    override func configureView() {
        contentView.backgroundColor = .clear
    }

    func configure(item: Item) {
        iconView.image = UIImage(systemName: item.iconName)
        titleLabel.text = item.title
    }
}
