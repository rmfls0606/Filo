//
//  ChatOtherMessageCell.swift
//  Filo
//
//  Created by 이상민 on 2/6/26.
//

import UIKit
import SnapKit

final class ChatOtherMessageCell: BaseTableViewCell {

    private let avatarImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.layer.cornerRadius = 18
        view.clipsToBounds = true
        view.image = UIImage(systemName: "person")
        view.tintColor = GrayStyle.gray45.color
        view.backgroundColor = GrayStyle.gray75.color?.withAlphaComponent(0.4)
        return view
    }()

    private let bubbleView: UIView = {
        let view = UIView()
        view.backgroundColor = GrayStyle.gray75.color?.withAlphaComponent(0.6)
        view.layer.cornerRadius = 12
        return view
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.body2
        label.textColor = GrayStyle.gray15.color
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

        contentView.addSubview(avatarImageView)
        contentView.addSubview(bubbleView)
        contentView.addSubview(timeLabel)
        bubbleView.addSubview(messageLabel)

        avatarImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.bottom.equalTo(bubbleView.snp.bottom)
            make.size.equalTo(36)
        }

        bubbleView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(6)
            make.leading.equalTo(avatarImageView.snp.trailing).offset(8)
            make.bottom.equalToSuperview().inset(6)
            make.width.lessThanOrEqualTo(UIScreen.main.bounds.width * 0.66)
        }

        timeLabel.snp.makeConstraints { make in
            make.leading.equalTo(bubbleView.snp.trailing).offset(8)
            make.bottom.equalTo(bubbleView.snp.bottom)
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

    func bind(message: ChatResponseDTO) {
        messageLabel.text = message.content
        timeLabel.text = message.createdAt.toChatTimestamp()
        if let url = message.sender.profileImage {
            avatarImageView.setKFImage(urlString: url)
        } else {
            avatarImageView.image = nil
        }
    }
}
