//
//  TodayAuthorHashtagCollectionViewCell.swift
//  Filo
//
//  Created by 이상민 on 01/23/26.
//

import UIKit
import SnapKit

final class TodayAuthorHashtagCollectionViewCell: BaseCollectionViewCell {
    //MARK: - UI
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.caption1
        label.textColor = GrayStyle.gray60.color
        return label
    }()

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.layer.cornerRadius = contentView.bounds.height / 2
    }
    
    override func configureHierarchy() {
        contentView.addSubview(titleLabel)
    }

    override func configureLayout() {
        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16))
        }
    }

    override func configureView() {
        contentView.backgroundColor = Brand.blackTurquoise.color
        contentView.clipsToBounds = true
    }

    func configure(_ text: String) {
        titleLabel.text = text
    }
}
