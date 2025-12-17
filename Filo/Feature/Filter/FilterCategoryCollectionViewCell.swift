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
        contentView.layer.cornerRadius = self.frame.height / 2
        contentView.clipsToBounds = true
    }
    
    func configure(_ item: FilterCategoryEntity){
        titleLabel.text = item.type.rawValue
        
        contentView.backgroundColor = item.isSelected ? Brand.brightTurquoise.color : Brand.blackTurquoise.color
        titleLabel.textColor = item.isSelected ? GrayStyle.gray45.color : GrayStyle.gray75.color
    }
}
