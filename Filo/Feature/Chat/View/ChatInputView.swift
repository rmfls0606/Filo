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
    
    private var textViewHeightConstraint: Constraint?
    
    var inputText: ControlProperty<String>{
        return textView.rx.text.orEmpty
    }
    
    override func configureHierarchy() {
        addSubview(textView)
        addSubview(sendButton)
    }
    
    override func configureLayout() {
        sendButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(textView.snp.bottom).inset(6)
            make.size.equalTo(24)
        }
        
        textView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.trailing.equalTo(sendButton.snp.leading).offset(-8)
            make.top.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().inset(12)
            textViewHeightConstraint = make.height.equalTo(36).constraint
        }
    }
    
    override func configureView() {
        backgroundColor = GrayStyle.gray90.color
        updateTextViewHeight()
    }
    
    func updateTextViewHeight() {
        let maxLines: CGFloat = 8
        let lineHeight = textView.font?.lineHeight ?? 14
        let maxHeight = floor(lineHeight * maxLines)
        let size = textView.sizeThatFits(CGSize(width: textView.bounds.width, height: .greatestFiniteMagnitude))
        let height = min(maxHeight, ceil(size.height))
        textView.isScrollEnabled = size.height > maxHeight
        textViewHeightConstraint?.update(offset: height)
        layoutIfNeeded()
    }
}
