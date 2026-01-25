//
//  FilterValueCollectionViewCell.swift
//  Filo
//
//  Created by 이상민 on 1/25/26.
//

import UIKit
import SnapKit

final class FilterValueCollectionViewCell: BaseCollectionViewCell {
    private let iconView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.tintColor = GrayStyle.gray30.color
        return view
    }()
    
    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.body2
        label.textColor = GrayStyle.gray75.color
        label.textAlignment = .center
        return label
    }()

    override func configureHierarchy() {
        contentView.addSubview(iconView)
        contentView.addSubview(valueLabel)
    }
    
    override func configureLayout() {
        iconView.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.size.equalTo(32)
        }
        
        valueLabel.snp.makeConstraints { make in
            make.top.equalTo(iconView.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }
    }
    
    func configure(iconName: String, valueText: String) {
        iconView.image = UIImage(named: iconName)
        valueLabel.text = valueText
    }
}
