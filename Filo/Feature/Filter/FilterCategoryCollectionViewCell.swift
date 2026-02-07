//
//  FilterCategoryCollectionViewCell.swift
//  Filo
//
//  Created by 이상민 on 12/18/25.
//

import UIKit
import SnapKit

final class FilterCategoryCollectionViewCell: BaseCollectionViewCell {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.body2
        label.textAlignment = .center
        label.numberOfLines = 1
        label.lineBreakMode = .byClipping
        return label
    }()
    
    override func configureHierarchy() {
        contentView.addSubview(titleLabel)
    }
    
    override func configureLayout() {
        titleLabel.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(16)
            make.verticalEdges.equalToSuperview().inset(6)
        }
    }
    
    override func configureView() {
        contentView.layer.borderWidth = 1.0
        contentView.layer.borderColor = Brand.deepTurquoise.color?.cgColor
        contentView.clipsToBounds = true
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.layer.cornerRadius = contentView.bounds.height / 2
    }
    
    func configure(_ item: FilterCategoryEntity){
        titleLabel.text = item.type.rawValue
        
        contentView.backgroundColor = item.isSelected ? Brand.brightTurquoise.color : Brand.blackTurquoise.color
        titleLabel.textColor = item.isSelected ? GrayStyle.gray45.color : GrayStyle.gray75.color
    }

    func configure(title: String, isSelected: Bool) {
        titleLabel.text = title
        contentView.backgroundColor = isSelected ? Brand.brightTurquoise.color : Brand.blackTurquoise.color
        titleLabel.textColor = isSelected ? GrayStyle.gray45.color : GrayStyle.gray75.color
    }
}
