//
//  ChatMyMessageCell.swift
//  Filo
//
//  Created by 이상민 on 2/6/26.
//

import UIKit
import SnapKit

final class ChatMyMessageCell: UITableViewCell {

    private let bubbleView: UIView = {
        let view = UIView()
        view.backgroundColor = Brand.deepTurquoise.color
        view.layer.cornerRadius = 12
        return view
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.body2
        label.textColor = GrayStyle.gray45.color
        label.numberOfLines = 0
        return label
    }()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.caption2
        label.textColor = GrayStyle.gray60.color
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(timeLabel)
        contentView.addSubview(bubbleView)
        bubbleView.addSubview(messageLabel)

        timeLabel.snp.makeConstraints { make in
            make.trailing.equalTo(bubbleView.snp.leading).offset(-8)
            make.bottom.equalTo(bubbleView.snp.bottom)
        }

        bubbleView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(6)
            make.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(6)
            make.width.lessThanOrEqualTo(UIScreen.main.bounds.width * 0.66)
        }

        messageLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(8)
            make.horizontalEdges.equalToSuperview().inset(8)
        }

        messageLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(8)
            make.horizontalEdges.equalToSuperview().inset(8)
            make.bottom.equalToSuperview().inset(8)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(message: ChatResponseDTO) {
        messageLabel.text = message.content
        timeLabel.text = message.createdAt.toChatTimestamp()
    }
}
