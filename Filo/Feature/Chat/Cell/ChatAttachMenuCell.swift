//
//  ChatAttachMenuCell.swift
//  Filo
//
//  Created by 이상민 on 2/6/26.
//

import UIKit
import SnapKit

final class ChatAttachMenuCell: BaseCollectionViewCell {
    private let iconBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = Brand.deepTurquoise.color?.withAlphaComponent(0.18)
        view.layer.cornerRadius = 24
        return view
    }()

    private let iconView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.tintColor = Brand.brightTurquoise.color
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.body2
        label.textColor = GrayStyle.gray30.color
        label.textAlignment = .center
        return label
    }()
    
    override func configureHierarchy() {
        contentView.addSubview(iconBackgroundView)
        iconBackgroundView.addSubview(iconView)
        contentView.addSubview(titleLabel)
    }
    
    override func configureLayout() {
        iconBackgroundView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.size.equalTo(48)
        }

        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(28)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconBackgroundView.snp.bottom).offset(8)
            make.horizontalEdges.equalToSuperview().inset(2)
            make.bottom.equalToSuperview()
        }
    }

    func configure(title: String, systemImage: String) {
        titleLabel.text = title
        iconView.image = UIImage(systemName: systemImage)
    }
}
