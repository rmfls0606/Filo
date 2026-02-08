//
//  ChatMyMessageCell.swift
//  Filo
//
//  Created by 이상민 on 2/6/26.
//

import UIKit
import SnapKit

final class ChatMyMessageCell: BaseTableViewCell {
    var onAttachmentTap: (([String], Int) -> Void)?

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

    private let attachmentsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 6
        stack.distribution = .fill
        return stack
    }()

    private var files: [String] = []
    private var messageBottomConstraint: Constraint?
    private var messageTopToAttachments: Constraint?
    private var messageTopToBubble: Constraint?
    private var bubbleMinWidthConstraint: Constraint?
    private var bubbleMaxWidthConstraint: Constraint?
    private let attachmentMinBubbleWidth: CGFloat = 196
    private let attachmentItemHeight: CGFloat = 72
    private let attachmentLineSpacing: CGFloat = 6

    override func configureHierarchy() {
        contentView.addSubview(timeLabel)
        contentView.addSubview(bubbleView)
        bubbleView.addSubview(attachmentsStack)
        bubbleView.addSubview(messageLabel)
    }
    
    override func configureLayout() {
        timeLabel.snp.makeConstraints { make in
            make.leading.greaterThanOrEqualToSuperview().inset(20)
            make.trailing.equalTo(bubbleView.snp.leading).offset(-8)
            make.bottom.equalTo(bubbleView.snp.bottom)
        }

        bubbleView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(6)
            make.leading.greaterThanOrEqualToSuperview().inset(60)
            make.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(6)
            bubbleMinWidthConstraint = make.width.greaterThanOrEqualTo(88).constraint
            bubbleMinWidthConstraint?.deactivate()
            bubbleMaxWidthConstraint = make.width.lessThanOrEqualTo(0).constraint
            bubbleMaxWidthConstraint?.deactivate()
        }

        attachmentsStack.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(8)
            make.leading.equalToSuperview().inset(8)
            make.trailing.equalToSuperview().inset(8)
            make.height.equalTo(0)
        }

        messageLabel.snp.makeConstraints { make in
            messageTopToAttachments = make.top.equalTo(attachmentsStack.snp.bottom).offset(8).constraint
            messageTopToBubble = make.top.equalToSuperview().inset(8).constraint
            messageTopToBubble?.deactivate()
            make.horizontalEdges.equalToSuperview().inset(8)
            messageBottomConstraint = make.bottom.equalToSuperview().inset(8).constraint
        }
    }

    override func configureView() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        timeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        timeLabel.setContentHuggingPriority(.required, for: .horizontal)
        bubbleView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        bubbleView.setContentHuggingPriority(.required, for: .horizontal)
    }

    func configure(message: ChatResponseDTO) {
        messageLabel.text = message.content
        messageLabel.textAlignment = .right
        timeLabel.text = message.createdAt.toChatTimestamp()
        files = message.files
        let height: CGFloat = files.isEmpty ? 0 : attachmentsHeight(for: files.count)
        attachmentsStack.snp.updateConstraints { make in
            make.height.equalTo(height)
        }
        attachmentsStack.isHidden = files.isEmpty
        if files.isEmpty {
            attachmentsStack.isHidden = true
            attachmentsStack.snp.updateConstraints { make in
                make.height.equalTo(0)
            }
            messageTopToAttachments?.deactivate()
            messageTopToBubble?.activate()
            bubbleMinWidthConstraint?.deactivate()
            bubbleMaxWidthConstraint?.deactivate()
        } else {
            attachmentsStack.isHidden = false
            attachmentsStack.snp.updateConstraints { make in
                make.height.equalTo(attachmentsHeight(for: files.count))
            }
            messageTopToBubble?.deactivate()
            messageTopToAttachments?.activate()
            updateBubbleMinWidth()
        }
        rebuildAttachments()
        updateBubbleMinWidth()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateBubbleMinWidth()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onAttachmentTap = nil
    }
}

private extension ChatMyMessageCell {
    func attachmentsHeight(for count: Int) -> CGFloat {
        guard count > 0 else { return 0 }
        return (attachmentItemHeight * CGFloat(count)) + (attachmentLineSpacing * CGFloat(max(0, count - 1)))
    }

    func updateBubbleMinWidth() {
        let containerWidth = contentView.bounds.width
        guard containerWidth > 0 else { return }
        let timeWidth = timeLabel.intrinsicContentSize.width
        let maxAllowed = max(0, containerWidth - timeWidth - 48)

        let messageText = messageLabel.text ?? ""
        let messageFont = messageLabel.font ?? UIFont.systemFont(ofSize: 14)
        let messageTextWidth = ceil((messageText as NSString).size(withAttributes: [.font: messageFont]).width)

        if files.isEmpty {
            guard !messageText.isEmpty else {
                bubbleMinWidthConstraint?.deactivate()
                bubbleMaxWidthConstraint?.deactivate()
                return
            }
            let final = min(messageTextWidth + 16, maxAllowed)
            bubbleMinWidthConstraint?.deactivate()
            bubbleMaxWidthConstraint?.update(offset: final)
            bubbleMaxWidthConstraint?.activate()
            return
        }

        let fileNameFont = UIFont.Pretendard.caption1
        var required: CGFloat = 72
        for url in files {
            let ext = fileExtension(from: url)
            let isImage = ext.isEmpty || ["jpg", "jpeg", "png", "heic", "gif"].contains(ext)
            if isImage {
                required = max(required, 72)
            } else {
                let name = fileName(from: url)
                let nameWidth = ceil((name as NSString).size(withAttributes: [.font: fileNameFont]).width)
                required = max(required, 72 + 8 + nameWidth + 1)
            }
        }
        let contentRequired = max(required + 16, messageTextWidth + 16)
        let final = max(88, min(contentRequired, maxAllowed))
        bubbleMinWidthConstraint?.update(offset: final)
        bubbleMinWidthConstraint?.activate()
        bubbleMaxWidthConstraint?.update(offset: final)
        bubbleMaxWidthConstraint?.activate()
    }

    func fileExtension(from urlString: String) -> String {
        if let url = URL(string: urlString), !url.pathExtension.isEmpty {
            return url.pathExtension.lowercased()
        }
        if let components = URLComponents(string: urlString) {
            let ext = (components.path as NSString).pathExtension
            if !ext.isEmpty {
                return ext.lowercased()
            }
        }
        let trimmed = urlString.split(separator: "?").first.map(String.init) ?? urlString
        return (trimmed as NSString).pathExtension.lowercased()
    }

    func fileName(from urlString: String) -> String {
        if let url = URL(string: urlString) {
            let name = url.lastPathComponent
            if !name.isEmpty {
                return name
            }
        }
        if let components = URLComponents(string: urlString) {
            let name = components.path.split(separator: "/").last.map(String.init) ?? ""
            if !name.isEmpty {
                return name
            }
        }
        if let last = urlString.split(separator: "/").last {
            return String(last).split(separator: "?").first.map(String.init) ?? String(last)
        }
        return urlString
    }

    func rebuildAttachments() {
        attachmentsStack.arrangedSubviews.forEach { view in
            attachmentsStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        guard !files.isEmpty else { return }
        for (index, url) in files.enumerated() {
            let view = ChatAttachmentView()
            view.bind(urlString: url, alignThumbnailOnLeft: false)
            view.onTap = { [weak self] in
                guard let self else { return }
                self.onAttachmentTap?(self.files, index)
            }
            attachmentsStack.addArrangedSubview(view)
            view.snp.makeConstraints { make in
                make.height.equalTo(attachmentItemHeight)
                make.width.equalTo(attachmentsStack.snp.width)
            }
        }
        attachmentsStack.setNeedsLayout()
        attachmentsStack.layoutIfNeeded()
    }
}
