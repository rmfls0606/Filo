//
//  CommentsViewController.swift
//  Filo
//
//  Created by 이상민 on 2/7/26.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import IQKeyboardManagerSwift

final class CommentsViewController: BaseViewController {
    private let viewModel: CommentsViewModel
    private let disposeBag = DisposeBag()
    private let replyTargetRelay = BehaviorRelay<CommentReplyTarget?>(value: nil)
    private let editTargetRelay = BehaviorRelay<String?>(value: nil)
    private let expandRepliesRelay = PublishRelay<String>()
    private let deleteRelay = PublishRelay<String>()
    private var inputBottomConstraint: Constraint?
    private var currentUserId: String = ""
    var onCountChanged: ((Int) -> Void)?
    var onCommentsChanged: (([PostCommentResponseDTO]) -> Void)?
    var onPostNotFound: ((String) -> Void)?
    
    private let tableView: UITableView = {
        let view = UITableView()
        view.backgroundColor = .clear
        view.separatorStyle = .none
        view.showsVerticalScrollIndicator = false
        view.keyboardDismissMode = .interactive
        view.register(CommentTableViewCell.self, forCellReuseIdentifier: CommentTableViewCell.identifier)
        view.register(CommentMoreRepliesCell.self, forCellReuseIdentifier: CommentMoreRepliesCell.identifier)
        view.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 12, right: 0)
        return view
    }()
    
    private let replyInfoView: UIView = {
        let view = UIView()
        view.backgroundColor = GrayStyle.gray90
            .color
        view.layer.cornerRadius = 8
        view.isHidden = true
        return view
    }()
    
    private let replyInfoLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.caption2
        label.textColor = GrayStyle.gray45.color
        return label
    }()
    
    private let replyCancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = GrayStyle.gray60.color
        return button
    }()
    
    private let inputContainer: UIView = {
        let view = UIView()
        view.backgroundColor = GrayStyle.gray100.color
        view.layer.cornerRadius = 20
        view.layer.borderWidth = 1
        view.layer.borderColor = Brand.blackTurquoise.color?.cgColor
        view.clipsToBounds = true
        return view
    }()
    
    // 텍스트뷰 내 수직 중앙 정렬을 위한 커스텀 클래스
    private final class CenteredTextView: UITextView {
        override func layoutSubviews() {
            super.layoutSubviews()
            // 한 줄일 때만 중앙 정렬, 여러 줄이면 상단부터 채워지도록 설정 가능
            let size = self.sizeThatFits(CGSize(width: self.bounds.width, height: CGFloat.greatestFiniteMagnitude))
            var topOffset = (self.bounds.size.height - size.height * self.zoomScale) / 2
            topOffset = topOffset < 0.0 ? 0.0 : topOffset
            self.contentInset.top = topOffset
        }
    }
    
    private let inputTextView: UITextView = {
        let view = UITextView() // Centered 대신 일반을 쓰고 Inset으로 조절하는 게 멀티라인에 더 안정적입니다.
        view.font = .Pretendard.body2
        view.textColor = GrayStyle.gray30.color
        view.backgroundColor = .clear
        view.isScrollEnabled = false // 텍스트에 따라 높이가 늘어나도록 설정
        view.textContainerInset = .init(top: 8, left: 6, bottom: 8, right: 6)
        return view
    }()
    
    private let sendButton: UIButton = {
        var config = UIButton.Configuration.plain()
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        config.preferredSymbolConfigurationForImage = imageConfig
        config.baseForegroundColor = GrayStyle.gray75.color
        
        // 이미지 렌더링 방식 확인
        let image = UIImage(named: "message")?.withRenderingMode(.alwaysTemplate)
        config.image = image
        config.contentInsets = .zero
        
        let button = UIButton(configuration: config)
        button.imageView?.contentMode = .scaleAspectFit
        return button
    }()
    
    init(viewModel: CommentsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        IQKeyboardManager.shared.isEnabled = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        IQKeyboardManager.shared.isEnabled = true
    }
    
    override func configureHierarchy() {
        view.addSubview(tableView)
        view.addSubview(replyInfoView)
        replyInfoView.addSubview(replyInfoLabel)
        replyInfoView.addSubview(replyCancelButton)
        view.addSubview(inputContainer)
        inputContainer.addSubview(inputTextView)
        inputContainer.addSubview(sendButton)
    }
    
    override func configureLayout() {
        replyInfoView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(inputContainer.snp.top).offset(-6)
            make.height.equalTo(28)
        }
        
        replyInfoLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(10)
            make.centerY.equalToSuperview()
        }
        
        replyCancelButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()
            make.size.equalTo(18)
        }
        
        inputContainer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            self.inputBottomConstraint = make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-12).constraint
            make.height.greaterThanOrEqualTo(40)
        }
        
        sendButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(6)
            make.bottom.equalToSuperview().inset(6)
            make.size.equalTo(28)
        }
        
        inputTextView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(6)
            make.top.bottom.equalToSuperview().inset(2)
            make.trailing.equalTo(sendButton.snp.leading).offset(-4)
            make.height.greaterThanOrEqualTo(32)
            make.height.lessThanOrEqualTo(100)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalTo(replyInfoView.snp.top).offset(-6)
        }
    }
    
    override func configureView() {
        view.backgroundColor = GrayStyle.gray100.color
        let navTitle = UILabel()
        navTitle.text = "댓글"
        navTitle.font = .Pretendard.body1
        navTitle.textColor = GrayStyle.gray30.color
        navigationItem.titleView = navTitle
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: nil,
            action: nil
        )
        navigationItem.leftBarButtonItem?.tintColor = GrayStyle.gray60.color
        
        if let sheet = sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.largestUndimmedDetentIdentifier = .large
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        }
    }
    
    override func configureBind() {
        let input = CommentsViewModel.Input(
            viewWillAppear: rx.methodInvoked(#selector(UIViewController.viewWillAppear(_:))).map { _ in },
            sendTapped: sendButton.rx.tap.asObservable(),
            commentText: inputTextView.rx.text.orEmpty.asObservable(),
            replyTarget: replyTargetRelay.asObservable(),
            expandReplies: expandRepliesRelay.asObservable(),
            editTarget: editTargetRelay.asObservable(),
            deleteComment: deleteRelay.asObservable()
        )
        
        let output = viewModel.transform(input: input)

        input.viewWillAppear
            .bind(with: self) { owner, _ in
                owner.currentUserId = (try? KeychainManager.shared.read(key: .userId)) ?? ""
                owner.tableView.reloadData()
            }
            .disposed(by: disposeBag)
        
        output.comments
            .drive(tableView.rx.items) { tableView, _, item in
                switch item {
                case .comment(let row):
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: CommentTableViewCell.identifier) as? CommentTableViewCell else {
                        return UITableViewCell()
                    }
                    let myId = self.currentUserId.trimmingCharacters(in: .whitespacesAndNewlines)
                    let creatorId = row.creator.userID.trimmingCharacters(in: .whitespacesAndNewlines)
                    let showMore = !myId.isEmpty && creatorId == myId
                    cell.configure(item: row, showMore: showMore)
                    cell.replyTap
                        .bind(with: self) { owner, _ in
                            owner.replyTargetRelay.accept(CommentReplyTarget(commentId: row.commentId, nick: row.creator.nick))
                            owner.inputTextView.text = "@\(row.creator.nick) "
                            owner.inputTextView.becomeFirstResponder()
                            owner.inputTextView.setNeedsLayout()
                        }
                        .disposed(by: cell.disposeBag)
                    cell.configureMenu(
                        onEdit: { [weak self] in
                            self?.presentEdit(for: row)
                        },
                        onDelete: { [weak self] in
                            self?.presentDelete(for: row)
                        }
                    )
                    return cell
                case .moreReplies(let parentId, let remaining):
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: CommentMoreRepliesCell.identifier) as? CommentMoreRepliesCell else {
                        return UITableViewCell()
                    }
                    cell.configure(remaining: remaining)
                    return cell
                }
            }
            .disposed(by: disposeBag)
        
        output.sendEnabled
            .drive(with: self) { owner, enabled in
                owner.sendButton.isEnabled = enabled
                owner.sendButton.alpha = enabled ? 1.0 : 0.5
            }
            .disposed(by: disposeBag)
        
        output.sendSuccess
            .emit(with: self) { owner, _ in
                owner.inputTextView.text = ""
                owner.replyTargetRelay.accept(nil)
                owner.editTargetRelay.accept(nil)
                owner.inputTextView.isScrollEnabled = false
                owner.view.layoutIfNeeded()
            }
            .disposed(by: disposeBag)
        
        output.totalCount
            .drive(with: self) { owner, count in
                owner.onCountChanged?(count)
            }
            .disposed(by: disposeBag)

        output.rawComments
            .drive(with: self) { owner, comments in
                owner.onCommentsChanged?(comments)
            }
            .disposed(by: disposeBag)

        replyTargetRelay
            .bind(with: self) { owner, target in
                let editTarget = owner.editTargetRelay.value
                owner.replyInfoView.isHidden = (target == nil && editTarget == nil)
                if let target {
                    owner.replyInfoLabel.text = "\(target.nick)님에게 답글 작성 중"
                } else if editTarget != nil {
                    owner.replyInfoLabel.text = "댓글 수정 중"
                }
            }
            .disposed(by: disposeBag)
        
        editTargetRelay
            .bind(with: self) { owner, target in
                let replyTarget = owner.replyTargetRelay.value
                owner.replyInfoView.isHidden = (target == nil && replyTarget == nil)
                if let target {
                    owner.replyInfoLabel.text = "댓글 수정 중"
                } else if let replyTarget {
                    owner.replyInfoLabel.text = "\(replyTarget.nick)님에게 답글 작성 중"
                }
            }
            .disposed(by: disposeBag)

        inputTextView.rx.text.orEmpty
            .bind(with: self) { owner, _ in
                let size = CGSize(width: owner.inputTextView.frame.width, height: .infinity)
                let estimatedSize = owner.inputTextView.sizeThatFits(size)
                
                owner.inputTextView.isScrollEnabled = estimatedSize.height > 100
                owner.view.layoutIfNeeded()
            }
            .disposed(by: disposeBag)
        
        output.networkError
            .emit(with: self) { owner, error in
                if owner.shouldPopAfterError(error) {
                    owner.showAlert(title: "오류", message: error.errorDescription) { [weak owner] in
                        guard let owner else { return }
                        let postId = owner.viewModel.currentPostId
                        owner.dismiss(animated: true) {
                            owner.onPostNotFound?(postId)
                        }
                    }
                } else {
                    owner.showAlert(title: "오류", message: error.errorDescription)
                }
            }
            .disposed(by: disposeBag)

        tableView.rx.modelSelected(CommentListItem.self)
            .bind(with: self) { owner, item in
                if case let .moreReplies(parentId, _) = item {
                    owner.expandRepliesRelay.accept(parentId)
                }
            }
            .disposed(by: disposeBag)

        Observable.merge(
            NotificationCenter.default.rx.notification(UIResponder.keyboardWillShowNotification),
            NotificationCenter.default.rx.notification(UIResponder.keyboardWillHideNotification)
        )
        .bind(with: self) { owner, notification in
            owner.handleKeyboard(notification: notification)
        }
        .disposed(by: disposeBag)
        
        sendButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.inputTextView.resignFirstResponder()
            }
            .disposed(by: disposeBag)
        
        replyCancelButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.replyTargetRelay.accept(nil)
                owner.editTargetRelay.accept(nil)
                owner.inputTextView.text = ""
                owner.inputTextView.setNeedsLayout()
            }
            .disposed(by: disposeBag)
        
        navigationItem.leftBarButtonItem?.rx.tap
            .bind(with: self) { owner, _ in
                owner.dismiss(animated: true)
            }
            .disposed(by: disposeBag)
    }
    
    private func handleKeyboard(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        
        let keyboardHeight = keyboardFrame.cgRectValue.height
        let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
        
        if notification.name == UIResponder.keyboardWillShowNotification {
            let offset = -(keyboardHeight - view.safeAreaInsets.bottom + 12)
            inputBottomConstraint?.update(offset: offset)
        } else {
            inputBottomConstraint?.update(offset: -12)
        }
        
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func presentEdit(for row: CommentRow) {
        editTargetRelay.accept(row.commentId)
        inputTextView.text = row.content
        inputTextView.becomeFirstResponder()
        inputTextView.setNeedsLayout()
    }
    
    private func presentDelete(for row: CommentRow) {
        let alert = UIAlertController(title: "댓글 삭제", message: "댓글을 삭제할까요?", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)
        let deleteAction = UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            self?.deleteRelay.accept(row.commentId)
        }
        alert.addAction(cancelAction)
        alert.addAction(deleteAction)
        present(alert, animated: true)
    }

    private func shouldPopAfterError(_ error: NetworkError) -> Bool {
        if case .statusCodeError(let status) = error, status == .notFound {
            return true
        }
        if case .serverError(let dto) = error {
            return dto.message == "게시글을 찾을 수 없습니다."
        }
        return false
    }
}
