//
//  ChatMyMessageCell.swift
//  Filo
//
//  Created by 이상민 on 2/6/26.
//

import UIKit
import SnapKit

final class ChatMyMessageCell: BaseTableViewCell {

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

    private let attachmentsView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 6
        layout.minimumLineSpacing = 6
        layout.itemSize = CGSize(width: 72, height: 72)
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.showsHorizontalScrollIndicator = false
        view.backgroundColor = .clear
        return view
    }()

    private var files: [String] = []
    private var messageBottomConstraint: Constraint?
    private var messageTopToAttachments: Constraint?
    private var messageTopToBubble: Constraint?

    override func configureHierarchy() {
        contentView.addSubview(timeLabel)
        contentView.addSubview(bubbleView)
        bubbleView.addSubview(attachmentsView)
        bubbleView.addSubview(messageLabel)
    }
    
    override func configureLayout() {
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

        attachmentsView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(8)
            make.horizontalEdges.equalToSuperview().inset(8)
            make.height.equalTo(0)
        }

        messageLabel.snp.makeConstraints { make in
            messageTopToAttachments = make.top.equalTo(attachmentsView.snp.bottom).offset(8).constraint
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
        attachmentsView.register(ChatMessageAttachmentCell.self, forCellWithReuseIdentifier: ChatMessageAttachmentCell.identifier)
        attachmentsView.dataSource = self
    }

    func configure(message: ChatResponseDTO) {
        messageLabel.text = message.content
        timeLabel.text = message.createdAt.toChatTimestamp()
        files = message.files
        let height: CGFloat = files.isEmpty ? 0 : 72
        attachmentsView.snp.updateConstraints { make in
            make.height.equalTo(height)
        }
        attachmentsView.isHidden = files.isEmpty
        if files.isEmpty {
            attachmentsView.isHidden = true
            attachmentsView.snp.updateConstraints { make in
                make.height.equalTo(0)
            }
            messageTopToAttachments?.deactivate()
            messageTopToBubble?.activate()
        } else {
            attachmentsView.isHidden = false
            attachmentsView.snp.updateConstraints { make in
                make.height.equalTo(72)
            }
            messageTopToBubble?.deactivate()
            messageTopToAttachments?.activate()
        }
        attachmentsView.reloadData()
    }
}

extension ChatMyMessageCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        files.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ChatMessageAttachmentCell.identifier, for: indexPath) as? ChatMessageAttachmentCell else {
            return UICollectionViewCell()
        }
        cell.bind(urlString: files[indexPath.item])
        return cell
    }
}
