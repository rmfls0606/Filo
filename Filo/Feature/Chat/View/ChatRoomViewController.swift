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
import QuickLook
import Kingfisher

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
    private let attachmentPreviewDataSource = ChatAttachmentPreviewDataSource()
    private var previewTempURLs: [URL] = []
    
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
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        IQKeyboardManager.shared.isEnabled = true
        if isMovingFromParent || isBeingDismissed {
            clearPreviewTempFiles()
        }
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
                        cell.onAttachmentTap = { [weak self] files, selectedIndex in
                            self?.presentMessageAttachmentsPreview(urlStrings: files, selectedIndex: selectedIndex)
                        }
                        return cell
                    } else {
                        guard let cell = tableView.dequeueReusableCell(withIdentifier: ChatOtherMessageCell.identifier) as? ChatOtherMessageCell else {
                            return UITableViewCell()
                        }
                        cell.configure(message: messageItem.message)
                        cell.onAttachmentTap = { [weak self] files, selectedIndex in
                            self?.presentMessageAttachmentsPreview(urlStrings: files, selectedIndex: selectedIndex)
                        }
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

        inputViewContainer.previewAttachment
            .subscribe(with: self) { owner, selected in
                owner.presentAttachmentPreview(selected: selected)
            }
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

    private func presentAttachmentPreview(selected: ChatAttachmentItem) {
        clearPreviewTempFiles()
        let built: [(id: UUID, url: URL)] = currentAttachments.compactMap { item in
            guard let url = makePreviewURL(item: item) else { return nil }
            return (item.id, url)
        }
        guard !built.isEmpty else { return }

        let urls = built.map { $0.url }
        previewTempURLs = urls
        attachmentPreviewDataSource.urls = urls
        let selectedIndex = built.firstIndex { $0.id == selected.id } ?? 0

        let preview = QLPreviewController()
        preview.dataSource = attachmentPreviewDataSource
        preview.currentPreviewItemIndex = selectedIndex
        present(preview, animated: true)
    }

    private func makePreviewURL(item: ChatAttachmentItem) -> URL? {
        let ext = (item.fileName as NSString).pathExtension.lowercased()
        let fallback = item.isImage ? "jpg" : "pdf"
        let fileExt = ext.isEmpty ? fallback : ext
        let fileName = "chat-preview-\(UUID().uuidString).\(fileExt)"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try item.data.write(to: fileURL, options: .atomic)
            return fileURL
        } catch {
            return nil
        }
    }

    private func presentMessageAttachmentsPreview(urlStrings: [String], selectedIndex: Int) {
        guard urlStrings.indices.contains(selectedIndex) else { return }
        let vc = ChatMessageAttachmentPreviewViewController(sources: urlStrings, initialIndex: selectedIndex)
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }

    private func clearPreviewTempFiles() {
        guard !previewTempURLs.isEmpty else { return }
        let fileManager = FileManager.default
        for url in previewTempURLs {
            try? fileManager.removeItem(at: url)
        }
        previewTempURLs.removeAll()
        attachmentPreviewDataSource.urls = []
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

private final class ChatAttachmentPreviewDataSource: NSObject, QLPreviewControllerDataSource {
    var urls: [URL] = []

    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        urls.count
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        urls[index] as NSURL
    }
}

private final class ChatMessageAttachmentPreviewViewController: UIViewController {
    private let sources: [String]
    private var currentIndex: Int
    private var previewFileURL: URL?
    private var loadRequestID = UUID()
    private let quickLookDataSource = SinglePreviewDataSource()

    private let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.backgroundColor = .black
        return view
    }()

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .white
        return button
    }()

    private let openButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("PDF 열기", for: .normal)
        button.titleLabel?.font = .Pretendard.body2
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = Brand.deepTurquoise.color
        button.layer.cornerRadius = 12
        button.contentEdgeInsets = UIEdgeInsets(top: 14, left: 20, bottom: 14, right: 20)
        button.isHidden = true
        return button
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .large)
        view.hidesWhenStopped = true
        return view
    }()
    private let pageLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.caption1
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()

    init(sources: [String], initialIndex: Int) {
        self.sources = sources
        self.currentIndex = max(0, min(initialIndex, max(0, sources.count - 1)))
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configureUI()
        bindActions()
        bindSwipeGestures()
        loadPreview()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isBeingDismissed || isMovingFromParent {
            clearPreviewFile()
        }
    }

    private func configureUI() {
        view.addSubview(imageView)
        view.addSubview(closeButton)
        view.addSubview(openButton)
        view.addSubview(loadingIndicator)
        view.addSubview(pageLabel)

        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(12)
            make.trailing.equalToSuperview().inset(16)
            make.size.equalTo(30)
        }

        openButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(24)
            make.height.equalTo(50)
        }

        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        pageLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(openButton.snp.top).offset(-12)
        }
    }

    private func bindActions() {
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        openButton.addTarget(self, action: #selector(openPDFTapped), for: .touchUpInside)
    }

    private func bindSwipeGestures() {
        let left = UISwipeGestureRecognizer(target: self, action: #selector(showNext))
        left.direction = .left
        let right = UISwipeGestureRecognizer(target: self, action: #selector(showPrevious))
        right.direction = .right
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(left)
        imageView.addGestureRecognizer(right)
    }

    private func loadPreview() {
        guard sources.indices.contains(currentIndex) else { return }
        clearPreviewFile()
        imageView.image = nil
        openButton.isHidden = true
        pageLabel.text = "\(currentIndex + 1) / \(sources.count)"
        loadingIndicator.startAnimating()
        let requestID = UUID()
        loadRequestID = requestID
        Task { [weak self] in
            guard let self else { return }
            let source = self.sources[self.currentIndex]

            if let dataURI = decodeDataURI(source) {
                await renderPreview(data: dataURI.data, fileExtension: dataURI.fileExtension, requestID: requestID)
                return
            }

            if let url = resolveAttachmentURL(from: source),
               isImageSource(source) {
                await MainActor.run {
                    guard self.loadRequestID == requestID else { return }
                    self.loadRemoteImageFast(url: url, requestID: requestID)
                }
                return
            }

            guard let url = resolveAttachmentURL(from: source),
                  let fetched = await fetchAttachmentData(url: url) else {
                await MainActor.run {
                    guard self.loadRequestID == requestID else { return }
                    self.loadingIndicator.stopAnimating()
                }
                return
            }
            let ext = inferFileExtension(from: source, mimeType: fetched.mimeType)
            await renderPreview(data: fetched.data, fileExtension: ext, requestID: requestID)
        }
    }

    private func renderPreview(data: Data, fileExtension: String?, requestID: UUID) async {
        let ext = (fileExtension ?? "").lowercased()
        let isPDF = ext == "pdf" || looksLikePDF(data: data)

        if isPDF {
            let thumbnail = await makePDFThumbnail(data: data)
            let fileURL = makeTempFile(data: data, fileExtension: "pdf")
            await MainActor.run {
                guard self.loadRequestID == requestID else { return }
                self.imageView.image = thumbnail
                self.previewFileURL = fileURL
                self.openButton.isHidden = (fileURL == nil)
                self.loadingIndicator.stopAnimating()
            }
            return
        }

        let image = UIImage(data: data)
        await MainActor.run {
            guard self.loadRequestID == requestID else { return }
            self.imageView.image = image
            self.openButton.isHidden = true
            self.loadingIndicator.stopAnimating()
        }
    }

    private func loadRemoteImageFast(url: URL, requestID: UUID) {
        imageView.kf.cancelDownloadTask()
        imageView.setKFAbsoluteImage(url: url, fade: false) { [weak self] result in
            guard let self else { return }
            guard self.loadRequestID == requestID else { return }
            self.loadingIndicator.stopAnimating()
            if case .failure = result {
                self.imageView.image = UIImage(systemName: "exclamationmark.triangle")
                self.imageView.tintColor = .white
            }
        }
    }

    @objc
    private func closeTapped() {
        dismiss(animated: true)
    }

    @objc
    private func openPDFTapped() {
        guard let previewFileURL else { return }
        quickLookDataSource.url = previewFileURL
        let preview = QLPreviewController()
        preview.dataSource = quickLookDataSource
        present(preview, animated: true)
    }

    @objc
    private func showNext() {
        guard currentIndex + 1 < sources.count else { return }
        currentIndex += 1
        loadPreview()
    }

    @objc
    private func showPrevious() {
        guard currentIndex - 1 >= 0 else { return }
        currentIndex -= 1
        loadPreview()
    }

    private func makePDFThumbnail(data: Data) async -> UIImage? {
        await withCheckedContinuation { continuation in
            ThumbnailCache.shared.loadPDFThumbnail(data: data, size: CGSize(width: 360, height: 360)) { image in
                continuation.resume(returning: image)
            }
        }
    }

    private func makeTempFile(data: Data, fileExtension: String) -> URL? {
        let fileName = "chat-message-preview-\(UUID().uuidString).\(fileExtension)"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try data.write(to: fileURL, options: .atomic)
            return fileURL
        } catch {
            return nil
        }
    }

    private func fetchAttachmentData(url: URL) async -> (data: Data, mimeType: String?)? {
        var request = URLRequest(url: url)
        request.setValue(NetworkConfig.apiKey, forHTTPHeaderField: "SeSACKey")
        request.setValue(NetworkConfig.authorization, forHTTPHeaderField: "Authorization")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse,
               !(200..<300).contains(httpResponse.statusCode) {
                return nil
            }
            return (data: data, mimeType: response.mimeType)
        } catch {
            return nil
        }
    }

    private func resolveAttachmentURL(from urlString: String) -> URL? {
        if let url = URL(string: urlString), url.scheme != nil {
            return url
        }
        let trimmed = urlString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return URL(string: "\(NetworkConfig.baseURL)/\(trimmed)")
    }

    private func decodeDataURI(_ source: String) -> (data: Data, fileExtension: String?)? {
        guard source.hasPrefix("data:") else { return nil }
        guard let commaIndex = source.firstIndex(of: ",") else { return nil }
        let header = String(source[source.index(source.startIndex, offsetBy: 5)..<commaIndex])
        let payload = String(source[source.index(after: commaIndex)...])
        let mimeType = header.components(separatedBy: ";").first ?? ""
        guard let data = Data(base64Encoded: payload) else { return nil }
        return (data: data, fileExtension: mapExtension(mimeType: mimeType))
    }

    private func mapExtension(mimeType: String) -> String? {
        let lower = mimeType.lowercased()
        if lower.contains("pdf") { return "pdf" }
        if lower.contains("png") { return "png" }
        if lower.contains("jpeg") || lower.contains("jpg") { return "jpg" }
        if lower.contains("gif") { return "gif" }
        return nil
    }

    private func inferFileExtension(from source: String, mimeType: String?) -> String? {
        let ext = (source as NSString).pathExtension.lowercased()
        if !ext.isEmpty { return ext }
        if let mimeType {
            return mapExtension(mimeType: mimeType)
        }
        return nil
    }

    private func isImageSource(_ source: String) -> Bool {
        let ext = (source as NSString).pathExtension.lowercased()
        return ["jpg", "jpeg", "png", "gif", "heic", "webp"].contains(ext)
    }

    private func looksLikePDF(data: Data) -> Bool {
        guard data.count >= 4 else { return false }
        return data.prefix(4) == Data([0x25, 0x50, 0x44, 0x46]) // %PDF
    }

    private func clearPreviewFile() {
        if let previewFileURL {
            try? FileManager.default.removeItem(at: previewFileURL)
            self.previewFileURL = nil
        }
    }
}

private final class SinglePreviewDataSource: NSObject, QLPreviewControllerDataSource {
    var url: URL?

    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        url == nil ? 0 : 1
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        (url ?? URL(fileURLWithPath: "")) as NSURL
    }
}
