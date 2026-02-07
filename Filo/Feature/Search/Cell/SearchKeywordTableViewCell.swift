//
//  SearchKeywordTableViewCell.swift
//  Filo
//
//  Created by 이상민 on 2/7/26.
//

import UIKit
import SnapKit

final class SearchKeywordTableViewCell: BaseTableViewCell {
    
    private let iconView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(systemName: "magnifyingglass")
        view.tintColor = GrayStyle.gray60.color
        return view
    }()
    
    private let keywordLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.body1
        label.textColor = GrayStyle.gray30.color
        label.numberOfLines = 1
        return label
    }()
    
    override func configureHierarchy() {
        contentView.addSubview(iconView)
        contentView.addSubview(keywordLabel)
    }
    
    override func configureLayout() {
        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(18)
        }
        
        keywordLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().inset(16)
            make.verticalEdges.equalToSuperview().inset(12)
        }
    }
    
    override func configureView() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }
    
    func configure(text: String) {
        keywordLabel.text = text
    }
}

