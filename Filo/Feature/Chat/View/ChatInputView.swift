//
//  ChatInputView.swift
//  Filo
//
//  Created by 이상민 on 2/6/26.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class ChatInputView: BaseView {
    private let disposeBag = DisposeBag()
    let attachButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.tintColor = GrayStyle.gray30.color
        return button
    }()

    let sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(resource: .message), for: .normal)
        button.tintColor = GrayStyle.gray60.color
        button.isEnabled = false
        return button
    }()
    
    let textView: UITextView = {
        let view = UITextView()
        view.font = .Pretendard.body2
        view.textColor = GrayStyle.gray15.color
        view.backgroundColor = GrayStyle.gray100.color?.withAlphaComponent(0.6)
        view.layer.cornerRadius = 18
        view.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        view.isScrollEnabled = false
        view.showsVerticalScrollIndicator = false
        return view
    }()

    let attachmentsView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 6
        layout.minimumLineSpacing = 6
        layout.itemSize = CGSize(width: 72, height: 72)
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.showsHorizontalScrollIndicator = false
        view.backgroundColor = .clear
        view.isHidden = true
        return view
    }()

    let attachMenuCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 24
        layout.minimumLineSpacing = 24
        let item = (UIScreen.main.bounds.width - (20.0 * 2) - (24.0 * 3)) / 4
        layout.itemSize = CGSize(width: item, height: .greatestFiniteMagnitude)
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.isScrollEnabled = false
        view.backgroundColor = .clear
        view.contentInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        view.isHidden = true
        return view
    }()
    
    private var textViewHeightConstraint: Constraint?
    private var attachmentsHeightConstraint: Constraint?
    private var attachMenuHeightConstraint: Constraint?
    private var isAttachMenuVisible: Bool = false
    
    private let attachmentItemsRelay = BehaviorRelay<[ChatAttachmentItem]>(value: [])
    private let menuItemsRelay = BehaviorRelay<[ChatAttachMenuItem]>(value: [])
    private let removeAttachmentRelay = PublishRelay<UUID>()
    private let attachMenuSelectedRelay = PublishRelay<ChatAttachMenuItem>()
    
    var inputText: ControlProperty<String>{
        return textView.rx.text.orEmpty
    }

    var removeAttachment: Observable<UUID> {
        removeAttachmentRelay.asObservable()
    }

    var attachMenuSelected: Observable<ChatAttachMenuItem> {
        attachMenuSelectedRelay.asObservable()
    }
    
    override func configureHierarchy() {
        addSubview(attachmentsView)
        addSubview(attachButton)
        addSubview(textView)
        addSubview(sendButton)
        addSubview(attachMenuCollectionView)
    }
    
    override func configureLayout() {
        attachmentsView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(12)
            make.leading.trailing.equalToSuperview().inset(20)
            attachmentsHeightConstraint = make.height.equalTo(0).constraint
        }

        attachButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.bottom.equalTo(textView.snp.bottom).inset(6)
            make.size.equalTo(24)
        }

        sendButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(textView.snp.bottom).inset(6)
            make.size.equalTo(24)
        }
        
        textView.snp.makeConstraints { make in
            make.leading.equalTo(attachButton.snp.trailing).offset(20)
            make.trailing.equalTo(sendButton.snp.leading).offset(-20)
            make.top.equalTo(attachmentsView.snp.bottom).offset(8)
            make.bottom.equalTo(attachMenuCollectionView.snp.top).offset(-8)
            textViewHeightConstraint = make.height.equalTo(36).constraint
        }

        attachMenuCollectionView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            attachMenuHeightConstraint = make.height.equalTo(0).constraint
        }
    }
    
    override func configureView() {
        backgroundColor = GrayStyle.gray90.color
        attachmentsView.register(ChatComposerAttachmentCell.self, forCellWithReuseIdentifier: ChatComposerAttachmentCell.identifier)

        attachMenuCollectionView.register(ChatAttachMenuCell.self, forCellWithReuseIdentifier: ChatAttachMenuCell.identifier)
        updateTextViewHeight()

        attachmentItemsRelay
            .bind(to: attachmentsView.rx.items(
                cellIdentifier: ChatComposerAttachmentCell.identifier,
                cellType: ChatComposerAttachmentCell.self
            )) { [weak self] _, item, cell in
                cell.bind(item: item)
                cell.onRemove = { [weak self] in
                    self?.removeAttachmentRelay.accept(item.id)
                }
            }
            .disposed(by: disposeBag)

        menuItemsRelay
            .bind(to: attachMenuCollectionView.rx.items(
                cellIdentifier: ChatAttachMenuCell.identifier,
                cellType: ChatAttachMenuCell.self
            )) { _, item, cell in
                cell.configure(title: item.title, systemImage: item.systemImage)
            }
            .disposed(by: disposeBag)

        attachMenuCollectionView.rx.modelSelected(ChatAttachMenuItem.self)
            .bind(to: attachMenuSelectedRelay)
            .disposed(by: disposeBag)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let safe = safeAreaInsets
        attachMenuCollectionView.contentInset = UIEdgeInsets(
            top: 20,
            left: 20 + safe.left,
            bottom: 20 + safe.bottom,
            right: 20 + safe.right
        )
        if let layout = attachMenuCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            let spacing = layout.minimumInteritemSpacing
            let totalSpacing = spacing * 3
            let totalInset = attachMenuCollectionView.contentInset.left + attachMenuCollectionView.contentInset.right
            let available = attachMenuCollectionView.bounds.width - totalInset - totalSpacing
            if available > 0 {
                let item = floor(available / 4)
                let labelHeight = UIFont.Pretendard.caption1?.lineHeight ?? 12
                let height = 48 + 8 + ceil(labelHeight)
                layout.itemSize = CGSize(width: item, height: height)
            }
        }
        if isAttachMenuVisible {
            attachMenuHeightConstraint?.update(offset: attachMenuHeight())
        }
    }
    
    func updateTextViewHeight() {
        let maxLines: CGFloat = 8
        let lineHeight = textView.font?.lineHeight ?? 14
        let maxHeight = floor(lineHeight * maxLines + textView.textContainerInset.top + textView.textContainerInset.bottom) - 1
        let size = textView.sizeThatFits(CGSize(width: textView.bounds.width, height: .greatestFiniteMagnitude))
        let height = min(maxHeight, ceil(size.height))
        textView.isScrollEnabled = size.height > maxHeight
        textViewHeightConstraint?.update(offset: height)
        layoutIfNeeded()
    }

    func updateAttachments(_ items: [ChatAttachmentItem]) {
        attachmentItemsRelay.accept(items)
        attachmentsView.isHidden = items.isEmpty
        attachmentsHeightConstraint?.update(offset: items.isEmpty ? 0 : 72)
    }

    func updateAttachMenuItems(_ items: [ChatAttachMenuItem]) {
        menuItemsRelay.accept(items)
        attachMenuCollectionView.collectionViewLayout.invalidateLayout()
        attachMenuCollectionView.layoutIfNeeded()
        if isAttachMenuVisible {
            attachMenuHeightConstraint?.update(offset: attachMenuHeight())
        }
    }

    func updateAttachMenuVisible(_ visible: Bool) {
        isAttachMenuVisible = visible
        attachMenuCollectionView.isHidden = !visible
        attachMenuHeightConstraint?.update(offset: visible ? attachMenuHeight() : 0)
        layoutIfNeeded()
    }

    private func attachMenuHeight() -> CGFloat {
        attachMenuCollectionView.layoutIfNeeded()
        let contentHeight = attachMenuCollectionView.collectionViewLayout.collectionViewContentSize.height
        let inset = attachMenuCollectionView.contentInset
        return contentHeight + inset.top + inset.bottom
    }
}
