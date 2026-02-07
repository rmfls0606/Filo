//
//  CommentMoreRepliesCell.swift
//  Filo
//
//  Created by 이상민 on 2/7/26.
//

import UIKit
import SnapKit

final class CommentMoreRepliesCell: BaseTableViewCell {
    private let label: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.caption2
        label.textColor = Brand.deepTurquoise.color
        return label
    }()
    
    override func configureHierarchy() {
        contentView.addSubview(label)
    }
    
    override func configureLayout() {
        label.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(54)
            make.top.equalToSuperview().inset(6)
            make.bottom.equalToSuperview().inset(6)
        }
    }
    
    override func configureView() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }
    
    func configure(remaining: Int) {
        label.text = "답글 더보기 (\(remaining))"
    }
}
