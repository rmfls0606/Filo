//
//  CommentTableViewCell.swift
//  Filo
//
//  Created by 이상민 on 2/7/26.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class CommentTableViewCell: BaseTableViewCell {    
    private let profileImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.layer.cornerRadius = 15
        view.backgroundColor = GrayStyle.gray75.color
        return view
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.caption1
        label.textColor = GrayStyle.gray30.color
        label.numberOfLines = 1
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.caption2
        label.textColor = GrayStyle.gray60.color
        label.numberOfLines = 1
        return label
    }()
    
    private let moreButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .regular)
        button.setImage(UIImage(systemName: "ellipsis")?.applyingSymbolConfiguration(config), for: .normal)
        button.tintColor = GrayStyle.gray60.color
        button.configuration = nil
        button.showsMenuAsPrimaryAction = true
        return button
    }()
    
    private let replyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("답글 달기", for: .normal)
        button.titleLabel?.font = .Pretendard.caption1
        button.setTitleColor(GrayStyle.gray60.color, for: .normal)
        button.contentHorizontalAlignment = .left
        return button
    }()
    
    private let contentLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.body2
        label.textColor = GrayStyle.gray30.color
        label.numberOfLines = 0
        return label
    }()
    
    private let headerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center
        return stack
    }()
    
    private let headerSpacer = UIView()
    
    private let textStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 2
        return stack
    }()
    
    private var profileLeadingConstraint: Constraint?
    let replyTap = PublishRelay<Void>()
    let moreTap = PublishRelay<Void>()
    private(set) var disposeBag = DisposeBag()
    
    override func configureHierarchy() {
        contentView.addSubview(profileImageView)
        contentView.addSubview(textStack)
        contentView.addSubview(moreButton)
        headerStack.addArrangedSubview(nameLabel)
        headerStack.addArrangedSubview(timeLabel)
        headerStack.addArrangedSubview(headerSpacer)
        textStack.addArrangedSubview(headerStack)
        textStack.addArrangedSubview(contentLabel)
        textStack.addArrangedSubview(replyButton)
    }
    
    override func configureLayout() {
        profileImageView.snp.makeConstraints { make in
            profileLeadingConstraint = make.leading.equalToSuperview().inset(14).constraint
            make.top.equalToSuperview().inset(10)
            make.size.equalTo(30)
        }
        
        moreButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(10)
            make.centerY.equalTo(nameLabel)
            make.size.equalTo(24)
        }
        
        textStack.snp.makeConstraints { make in
            make.leading.equalTo(profileImageView.snp.trailing).offset(10)
            make.trailing.equalTo(moreButton.snp.leading).offset(-8)
            make.top.equalTo(profileImageView)
            make.bottom.equalToSuperview().inset(10)
        }
    }
    
    override func configureView() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.bringSubviewToFront(moreButton)
        moreButton.setContentHuggingPriority(.required, for: .horizontal)
        moreButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        timeLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        timeLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        headerSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        headerSpacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        replyButton.rx.tap
            .bind(to: replyTap)
            .disposed(by: disposeBag)
        moreButton.rx.tap
            .bind(to: moreTap)
            .disposed(by: disposeBag)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        profileImageView.image = nil
        disposeBag = DisposeBag()
    }
    
    func configure(item: CommentRow, showMore: Bool) {
        nameLabel.text = item.creator.nick
        timeLabel.text = item.createdAt.toRelativeTimeString()
        if item.content.hasPrefix("@") {
            let text = item.content
            let attr = NSMutableAttributedString(string: text, attributes: [
                .font: UIFont.Pretendard.body2 as Any,
                .foregroundColor: GrayStyle.gray30.color as Any
            ])
            if let end = text.firstIndex(of: " ") {
                let length = text.distance(from: text.startIndex, to: end)
                attr.addAttributes([
                    .foregroundColor: Brand.brightTurquoise.color as Any
                ], range: NSRange(location: 0, length: length))
            }
            contentLabel.attributedText = attr
        } else {
            contentLabel.attributedText = nil
            contentLabel.text = item.content
        }
        replyButton.isHidden = item.isReply
        profileLeadingConstraint?.update(offset: item.isReply ? 26 : 14)
        textStack.layoutMargins = .zero
        textStack.isLayoutMarginsRelativeArrangement = false
        moreButton.isHidden = !showMore
        layoutIfNeeded()
        
        if let url = item.creator.profileImage {
            profileImageView.setKFImage(urlString: url)
        } else {
            profileImageView.image = nil
        }
    }
    
    func configureMenu(onEdit: @escaping () -> Void, onDelete: @escaping () -> Void) {
        let edit = UIAction(title: "수정") { _ in onEdit() }
        let delete = UIAction(title: "삭제", attributes: .destructive) { _ in onDelete() }
        moreButton.menu = UIMenu(title: "", children: [edit, delete])
    }
    
}
