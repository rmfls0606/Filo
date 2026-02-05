//
//  ChatDateSeparatorCell.swift
//  Filo
//
//  Created by 이상민 on 2/6/26.
//

import UIKit
import SnapKit

final class ChatDateSeparatorCell: BaseTableViewCell {
    private let pillView: UIView = {
        let view = UIView()
        view.backgroundColor = GrayStyle.gray75.color?.withAlphaComponent(0.45)
        view.layer.cornerRadius = 12
        return view
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.caption2
        label.textColor = GrayStyle.gray60.color
        label.textAlignment = .center
        return label
    }()

    override func configureHierarchy() {
        contentView.addSubview(pillView)
        pillView.addSubview(dateLabel)
    }

    override func configureLayout() {
        pillView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.bottom.equalToSuperview().inset(8)
        }

        dateLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }
    }

    override func configureView() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }

    func bind(title: String) {
        dateLabel.text = title
    }
}
