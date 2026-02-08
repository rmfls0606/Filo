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
import IQKeyboardManagerSwift
import PhotosUI
import UniformTypeIdentifiers

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
    private let dismissKeyboardTapGesture = UITapGestureRecognizer()
    private var listItems: [ChatListItem] = []
    private var currentAttachments: [ChatAttachmentItem] = []
    private let addAttachmentsRelay = PublishRelay<[ChatAttachmentItem]>()
    private var inputBottomConstraint: Constraint?
    
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
            inputBottomConstraint = make.bottom.equalTo(view.safeAreaLayoutGuide).constraint
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
        dismissKeyboardTapGesture.cancelsTouchesInView = false
        tableView.addGestureRecognizer(dismissKeyboardTapGesture)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        IQKeyboardManager.shared.isEnabled = false
        CurrentChatRoom.shared.roomId = viewModel.currentRoomId
        if let roomId = viewModel.currentRoomId {
            ChatLocalStore.shared.resetUnread(roomId: roomId)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        IQKeyboardManager.shared.isEnabled = true
        if CurrentChatRoom.shared.roomId == viewModel.currentRoomId {
            CurrentChatRoom.shared.roomId = nil
        }
    }

    override func configureBind() {
        let input = ChatRoomViewModel.Input(
            viewWillAppear: rx.methodInvoked(#selector(UIViewController.viewWillAppear)).map { _ in },
            viewWillDisappear: rx.methodInvoked(#selector(UIViewController.viewWillDisappear)).map { _ in },
            sendTapped: inputViewContainer.sendButton.rx.tap.asObservable(),
            textChanged: inputViewContainer.inputText.asObservable(),
            addAttachments: addAttachmentsRelay.asObservable(),
            removeAttachment: inputViewContainer.removeAttachment,
            attachMenuToggle: inputViewContainer.attachButton.rx.tap.asObservable(),
            attachMenuSelected: inputViewContainer.attachMenuSelected
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
                owner.scrollToBottom(animated: false)
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
                owner.scrollToBottom(animated: true)
            }
            .disposed(by: disposeBag)

        output.attachments
            .drive(with: self) { owner, items in
                owner.currentAttachments = items
                owner.inputViewContainer.updateAttachments(items)
            }
            .disposed(by: disposeBag)

        output.attachMenuItems
            .drive(with: self) { owner, items in
                owner.inputViewContainer.updateAttachMenuItems(items)
            }
            .disposed(by: disposeBag)

        output.isAttachMenuVisible
            .drive(with: self) { owner, visible in
                owner.inputViewContainer.updateAttachMenuVisible(visible)
            }
            .disposed(by: disposeBag)

        output.networkError
            .emit(with: self) { owner, error in
                owner.showAlert(title: "오류", message: error.errorDescription)
            }
            .disposed(by: disposeBag)

        inputViewContainer.attachMenuSelected
            .subscribe(onNext: { [weak self] item in
                self?.handleAttachMenuSelection(item)
            })
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx.notification(UIResponder.keyboardWillChangeFrameNotification)
            .bind(with: self) { owner, notification in
                owner.handleKeyboard(notification: notification)
            }
            .disposed(by: disposeBag)
        
        dismissKeyboardTapGesture.rx.event
            .bind(with: self) { owner, _ in
                owner.view.endEditing(true)
            }
            .disposed(by: disposeBag)
    }

    private func scrollToBottom(animated: Bool) {
        guard !listItems.isEmpty else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.tableView.layoutIfNeeded()
            let lastRow = self.listItems.count - 1
            guard lastRow >= 0 else { return }
            let indexPath = IndexPath(row: lastRow, section: 0)
            guard self.tableView.numberOfRows(inSection: 0) > lastRow else { return }
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
        }
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
    
    private func handleKeyboard(notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let frame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        else { return }
        
        let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        let curveRaw = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int ?? UIView.AnimationCurve.easeInOut.rawValue
        let curve = UIView.AnimationOptions(rawValue: UInt(curveRaw << 16))
        
        let keyboardFrameInView = view.convert(frame, from: nil)
        let overlap = max(0, view.bounds.maxY - keyboardFrameInView.minY - view.safeAreaInsets.bottom)
        inputBottomConstraint?.update(offset: -overlap)
        
        UIView.animate(withDuration: duration, delay: 0, options: [curve, .beginFromCurrentState, .allowUserInteraction]) {
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.scrollToBottom(animated: false)
        }
    }
}

extension ChatRoomViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        inputViewContainer.updateTextViewHeight()
    }
}

extension ChatRoomViewController: PHPickerViewControllerDelegate, UIDocumentPickerDelegate {
    private func handleAttachMenuSelection(_ item: ChatAttachMenuItem) {
        let remaining = max(0, 5 - currentAttachments.count)
        guard remaining > 0 else { return }
        switch item {
        case .photo:
            presentPhotoPicker(limit: remaining)
        case .file:
            presentFilePicker()
        }
    }

    private func presentPhotoPicker(limit: Int) {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = limit
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func presentFilePicker() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf])
        picker.allowsMultipleSelection = true
        picker.delegate = self
        present(picker, animated: true)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)
        guard !results.isEmpty else { return }

        let group = DispatchGroup()
        var items: [ChatAttachmentItem] = []

        for result in results {
            let provider = result.itemProvider
            let typeId = provider.registeredTypeIdentifiers.first ?? UTType.image.identifier
            let utType = UTType(typeId)
            group.enter()
            provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
                defer { group.leave() }
                guard let data else { return }
                let mime = utType?.preferredMIMEType ?? "image/jpeg"
                let ext = utType?.preferredFilenameExtension ?? "jpg"
                let baseName = provider.suggestedName ?? "photo_\(UUID().uuidString)"
                let fileName = baseName.contains(".") ? baseName : "\(baseName).\(ext)"
                items.append(ChatAttachmentItem(data: data, fileName: fileName, mimeType: mime, isImage: true))
            }
        }

        group.notify(queue: .main) { [weak self] in
            self?.addAttachmentsRelay.accept(items)
        }
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard !urls.isEmpty else { return }
        let remaining = max(0, 5 - currentAttachments.count)
        guard remaining > 0 else { return }
        var items: [ChatAttachmentItem] = []
        for url in urls.prefix(remaining) {
            let canAccess = url.startAccessingSecurityScopedResource()
            defer {
                if canAccess { url.stopAccessingSecurityScopedResource() }
            }
            guard let data = try? Data(contentsOf: url) else { continue }
            let fileName = url.lastPathComponent
            items.append(ChatAttachmentItem(data: data, fileName: fileName, mimeType: "application/pdf", isImage: false))
        }
        addAttachmentsRelay.accept(items)
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
