//
//  ChatRoomViewController.swift
//  Filo
//
//  Created by 이상민 on 2/6/26.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class ChatRoomViewController: BaseViewController {
    //MARK: - UI
    private let tableView: UITableView = {
        let view = UITableView()
        view.separatorStyle = .none
        view.backgroundColor = .clear
        view.rowHeight = UITableView.automaticDimension
        view.register(ChatMyMessageCell.self, forCellReuseIdentifier: ChatMyMessageCell.identifier)
        view.register(ChatOtherMessageCell.self, forCellReuseIdentifier: ChatOtherMessageCell.identifier)
        view.register(ChatDateSeparatorCell.self, forCellReuseIdentifier: ChatDateSeparatorCell.identifier)
        view.allowsSelection = false
        return view
    }()

    private let inputViewContainer = ChatInputView()
    private let inputBottomFillView: UIView = {
        let view = UIView()
        view.backgroundColor = GrayStyle.gray90.color
        return view
    }()

    //MARK: - Properties
    private let viewModel: ChatRoomViewModel
    private let initialTitle: String?
    private let disposeBag = DisposeBag()
    private var listItems: [ChatListItem] = []
    
    override var prefersCustomTabBarHidden: Bool { true }
    
    init(viewModel: ChatRoomViewModel, title: String? = nil) {
        self.viewModel = viewModel
        self.initialTitle = title
        super.init(nibName: nil, bundle: nil)
    }

    override func configureHierarchy() {
        view.addSubview(tableView)
        view.addSubview(inputBottomFillView)
        view.addSubview(inputViewContainer)
    }

    override func configureLayout() {
        tableView.snp.makeConstraints { make in
            make.top.horizontalEdges.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalTo(inputViewContainer.snp.top)
        }

        inputViewContainer.snp.makeConstraints { make in
            make.horizontalEdges.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        inputBottomFillView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }

    override func configureView() {
        view.backgroundColor = GrayStyle.gray100.color
        inputViewContainer.textView.delegate = self
        inputBottomFillView.backgroundColor = inputViewContainer.backgroundColor
        navigationItem.title = initialTitle ?? "채팅"
    }

    override func configureBind() {
        let input = ChatRoomViewModel.Input(
            viewWillAppear: rx.methodInvoked(#selector(UIViewController.viewWillAppear)).map { _ in },
            viewWillDisappear: rx.methodInvoked(#selector(UIViewController.viewWillDisappear)).map { _ in },
            sendTapped: inputViewContainer.sendButton.rx.tap,
            textChanged: inputViewContainer.inputText
        )

        let output = viewModel.transform(input: input)

        let listItemsDriver = output.messageItems
            .map { ChatListItemBuilder.build(from: $0) }
            .do(onNext: { [weak self] items in
                self?.listItems = items
            })

        listItemsDriver
            .drive(tableView.rx.items) { tableView, index, item in
                switch item {
                case .date(let title):
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: ChatDateSeparatorCell.identifier) as? ChatDateSeparatorCell else {
                        return UITableViewCell()
                    }
                    cell.bind(title: title)
                    return cell
                case .message(let messageItem):
                    if messageItem.isMine {
                        guard let cell = tableView.dequeueReusableCell(withIdentifier: ChatMyMessageCell.identifier) as? ChatMyMessageCell else {
                            return UITableViewCell()
                        }
                        cell.configure(message: messageItem.message)
                        return cell
                    } else {
                        guard let cell = tableView.dequeueReusableCell(withIdentifier: ChatOtherMessageCell.identifier) as? ChatOtherMessageCell else {
                            return UITableViewCell()
                        }
                        cell.configure(message: messageItem.message)
                        return cell
                    }
                }
            }
            .disposed(by: disposeBag)

        listItemsDriver
            .drive(with: self) { owner, _ in
                owner.updateTitleIfNeeded()
                owner.scrollToBottom()
            }
            .disposed(by: disposeBag)

        output.isSendEnabled
            .drive(with: self) { owner, enabled in
                owner.inputViewContainer.sendButton.isEnabled = enabled
                owner.inputViewContainer.sendButton.tintColor = enabled ? Brand.brightTurquoise.color : GrayStyle.gray60.color
            }
            .disposed(by: disposeBag)

        output.sendCompleted
            .emit(with: self) { owner, _ in
                owner.inputViewContainer.textView.text = ""
                owner.inputViewContainer.updateTextViewHeight()
            }
            .disposed(by: disposeBag)

        output.networkError
            .emit(with: self) { owner, error in
                owner.showAlert(title: "오류", message: error.errorDescription)
            }
            .disposed(by: disposeBag)
    }

    private func scrollToBottom() {
        guard !listItems.isEmpty else { return }
        let indexPath = IndexPath(row: listItems.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
    }

    private func updateTitleIfNeeded() {
        guard navigationItem.title == "채팅" else { return }
        let opponent = listItems.compactMap { item -> UserInfoResponseDTO? in
            guard case .message(let messageItem) = item else { return nil }
            return messageItem.message.sender
        }
        .first { $0.userID != viewModel.currentUserId }

        if let opponent {
            navigationItem.title = opponent.nick
        }
    }
}

extension ChatRoomViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        inputViewContainer.updateTextViewHeight()
    }
}

private enum ChatListItem {
    case date(String)
    case message(ChatMessageItem)
}

private enum ChatListItemBuilder {
    static func build(from items: [ChatMessageItem]) -> [ChatListItem] {
        var result: [ChatListItem] = []
        var lastDateKey: String?

        for item in items {
            let dateKey = item.message.createdAt.toChatSectionDate()
            if dateKey != lastDateKey {
                result.append(.date(dateKey))
                lastDateKey = dateKey
            }
            result.append(.message(item))
        }
        return result
    }
}
