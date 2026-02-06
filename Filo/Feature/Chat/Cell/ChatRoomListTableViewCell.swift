//
//  ChatRoomListTableViewCell.swift
//  Filo
//
//  Created by 이상민 on 2/6/26.
//

import UIKit
import SnapKit

final class ChatRoomListTableViewCell: BaseTableViewCell {
    private let avatarImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.layer.cornerRadius = 22
        view.clipsToBounds = true
        view.image = UIImage(systemName: "personp")?.withTintColor(GrayStyle.gray75.color ?? .gray75)
        view.backgroundColor = GrayStyle.gray75.color?.withAlphaComponent(0.4)
        return view
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.body2
        label.textColor = GrayStyle.gray30.color
        return label
    }()

    private let lastMessageLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.caption1
        label.textColor = GrayStyle.gray60.color
        label.numberOfLines = 2
        return label
    }()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.caption2
        label.textColor = GrayStyle.gray75.color
        label.textAlignment = .right
        return label
    }()

    private let unreadBadgeLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.caption2
        label.textColor = GrayStyle.gray0.color
        label.backgroundColor = .systemRed
        label.textAlignment = .center
        label.layer.cornerRadius = 10
        label.clipsToBounds = true
        label.isHidden = true
        return label
    }()

    private let contentStack: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 6
        return view
    }()

    private let timeStack: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.alignment = .trailing
        view.spacing = 6
        return view
    }()

    private var unreadBadgeWidthConstraint: Constraint?
    
    override func configureHierarchy() {
        contentView.addSubview(avatarImageView)
        contentView.addSubview(contentStack)
        contentView.addSubview(timeStack)

        contentStack.addArrangedSubview(nameLabel)
        contentStack.addArrangedSubview(lastMessageLabel)
        timeStack.addArrangedSubview(timeLabel)
        timeStack.addArrangedSubview(unreadBadgeLabel)
    }
    
    override func configureLayout() {
        avatarImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.size.equalTo(44)
        }

        timeStack.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.top.equalToSuperview().inset(18)
        }

        unreadBadgeLabel.snp.makeConstraints { make in
            make.height.equalTo(20)
            unreadBadgeWidthConstraint = make.width.greaterThanOrEqualTo(20).constraint
        }

        contentStack.snp.makeConstraints { make in
            make.leading.equalTo(avatarImageView.snp.trailing).offset(12)
            make.trailing.lessThanOrEqualTo(timeStack.snp.leading).offset(-12)
            make.centerY.equalToSuperview()
        }
    }

    override func configureView() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }

    func configure(room: ChatRoomResponseDTO, currentUserId: String) {
        let opponent = room.participants.first { $0.userID != currentUserId }
        nameLabel.text = opponent?.nick ?? "알 수 없음"
        if let lastChat = room.lastChat {
            lastMessageLabel.text = lastChat.content.isEmpty ? "" : lastChat.content
            timeLabel.text = lastChat.createdAt.toChatTimestamp()
        } else {
            lastMessageLabel.text = "대화를 시작해보세요"
            timeLabel.text = ""
        }
        if let url = opponent?.profileImage {
            avatarImageView.setKFImage(urlString: url)
        } else {
            avatarImageView.image = nil
        }
    }

    func configure(room: ChatRoomResponseDTO, currentUserId: String, cachedUser: UserInfoResponseDTO?) {
        let opponent = cachedUser ?? room.participants.first { $0.userID != currentUserId }
        nameLabel.text = opponent?.nick ?? "알 수 없음"
        if let lastChat = room.lastChat {
            lastMessageLabel.text = lastChat.content.isEmpty ? "" : lastChat.content
            timeLabel.text = lastChat.createdAt.toChatTimestamp()
        } else {
            lastMessageLabel.text = "대화를 시작해보세요"
            timeLabel.text = ""
        }
        if let url = opponent?.profileImage {
            avatarImageView.setKFImage(urlString: url)
        } else {
            avatarImageView.image = nil
        }
    }

    func configure(summary: ChatRoomSummaryEntity, cachedUser: UserInfoResponseDTO?) {
        nameLabel.text = cachedUser?.nick ?? "알 수 없음"
        lastMessageLabel.text = summary.lastMessage.isEmpty ? "대화를 시작해보세요" : summary.lastMessage
        timeLabel.text = summary.lastMessageAt.isEmpty ? "" : summary.lastMessageAt.toChatTimestamp()
        if let url = cachedUser?.profileImage {
            avatarImageView.setKFImage(urlString: url)
        } else {
            avatarImageView.image = nil
        }

        if summary.unreadCount > 0 {
            unreadBadgeLabel.isHidden = false
            unreadBadgeLabel.text = summary.unreadCount >= 300 ? "300+" : "\(summary.unreadCount)"
            unreadBadgeLabel.layoutIfNeeded()
            let width = max(20, unreadBadgeLabel.intrinsicContentSize.width + 10)
            unreadBadgeWidthConstraint?.update(offset: width)
        } else {
            unreadBadgeLabel.isHidden = true
        }
    }
}
