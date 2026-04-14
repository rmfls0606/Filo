//
//  CommunityDetailViewController.swift
//  Filo
//
//  Created by 이상민 on 2/7/26.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import AVKit

final class CommunityDetailViewController: BaseViewController {
    override var prefersCustomTabBarHidden: Bool { true }
    
    // MARK: - Properties
    private let viewModel: CommunityDetailViewModel
    private let disposeBag = DisposeBag()
    private let mediaItemsRelay = BehaviorRelay<[String]>(value: [])
    private let refreshRelay = PublishRelay<Void>()
    private var currentMediaIndex: Int = 0
    
    // MARK: - UI
    private let scrollView: UIScrollView = {
        let view = UIScrollView()
        view.showsVerticalScrollIndicator = false
        return view
    }()
    
    private let contentView = UIView()
    
    private let headerView = UIView()
    
    private let profileImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.layer.cornerRadius = 20
        view.backgroundColor = GrayStyle.gray75.color
        return view
    }()
    
    private let nickLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.body2
        label.textColor = GrayStyle.gray45.color
        label.numberOfLines = 1
        return label
    }()

    private let moreButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "ellipsis")
        config.baseForegroundColor = GrayStyle.gray60.color
        config.contentInsets = .zero
        let button = UIButton(configuration: config)
        button.isHidden = true
        button.showsMenuAsPrimaryAction = true
        return button
    }()
    
    private lazy var mediaCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.isPagingEnabled = true
        view.showsHorizontalScrollIndicator = false
        view.backgroundColor = .clear
        view.register(CommunityDetailMediaCell.self, forCellWithReuseIdentifier: CommunityDetailMediaCell.identifier)
        return view
    }()
    
    private let pageCountBadge: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.caption2
        label.textColor = GrayStyle.gray45.color
        label.backgroundColor = GrayStyle.gray75.color?.withAlphaComponent(0.6)
        label.textAlignment = .center
        label.layer.cornerRadius = 12
        label.clipsToBounds = true
        label.isHidden = true
        return label
    }()

    private let pageControl: UIPageControl = {
        let view = UIPageControl()
        view.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        view.currentPageIndicatorTintColor = Brand.deepTurquoise.color
        view.pageIndicatorTintColor = GrayStyle.gray75.color
        view.hidesForSinglePage = true
        view.isUserInteractionEnabled = false
        return view
    }()
    
    private let actionStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        stack.distribution = .fill
        return stack
    }()

    private let likeStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 2
        stack.alignment = .center
        return stack
    }()

    private let commentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 2
        stack.alignment = .center
        return stack
    }()
    
    private let likeButton: LikeButton = {
        let btn = LikeButton()
        btn.selectedColor = .systemRed
        return btn
    }()
    
    private let commentButton: UIButton = {
        var config = UIButton.Configuration.plain()
        var imageConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        config.image = UIImage(systemName: "message")
        config.preferredSymbolConfigurationForImage = imageConfig
        config.baseForegroundColor = GrayStyle.gray60.color
        config.contentInsets = .zero
        let button = UIButton(configuration: config)
        return button
    }()

    private let likeCountLabel: UILabel = {
        let label = UILabel()
        label.text = "0"
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        label.textColor = GrayStyle.gray45.color
        label.numberOfLines = 1
        return label
    }()
    
    private let commentCountLabel: UILabel = {
        let label = UILabel()
        label.text = "0"
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        label.textColor = GrayStyle.gray45.color
        label.numberOfLines = 1
        return label
    }()
    

    
    private let captionLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.body2
        label.textColor = GrayStyle.gray45.color
        label.numberOfLines = 0
        return label
    }()
    
    private let createdLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.caption2
        label.textColor = GrayStyle.gray60.color
        label.numberOfLines = 1
        return label
    }()
    
    private var pageControlHeightConstraint: Constraint?
    private let menuActionRelay = PublishRelay<CommunityDetailViewModel.MenuAction>()
    private var currentPostId: String?
    private var lastComments: [PostCommentResponseDTO] = []
    private var currentCreatorId: String?
    private var currentDetail: PostResponseDTO?
    private var isAutoPlayEnabled: Bool = true
    private let initialPostId: String
    var onDeleted: ((String) -> Void)?
    var onUpdated: ((String) -> Void)?
    
    init(viewModel: CommunityDetailViewModel, initialPostId: String) {
        self.viewModel = viewModel
        self.initialPostId = initialPostId
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let layout = mediaCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            let size = mediaCollectionView.bounds.size
            if layout.itemSize != size {
                layout.itemSize = size
                layout.invalidateLayout()
            }
        }
    }
    
    override func configureHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(headerView)
        headerView.addSubview(profileImageView)
        headerView.addSubview(nickLabel)
        headerView.addSubview(moreButton)
        
        contentView.addSubview(mediaCollectionView)
        contentView.addSubview(pageCountBadge)
        contentView.addSubview(pageControl)

        contentView.addSubview(actionStack)
        actionStack.addArrangedSubview(likeStack)
        actionStack.addArrangedSubview(commentStack)
        likeStack.addArrangedSubview(likeButton)
        likeStack.addArrangedSubview(likeCountLabel)
        commentStack.addArrangedSubview(commentButton)
        commentStack.addArrangedSubview(commentCountLabel)

        contentView.addSubview(captionLabel)
        contentView.addSubview(createdLabel)
    }
    
    override func configureLayout() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        headerView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.top.equalToSuperview()
        }
        
        profileImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.verticalEdges.equalToSuperview().inset(12)
            make.size.equalTo(40)
        }
        
        nickLabel.snp.makeConstraints { make in
            make.leading.equalTo(profileImageView.snp.trailing).offset(12)
            make.centerY.equalTo(profileImageView)
            make.trailing.lessThanOrEqualTo(moreButton.snp.leading).offset(-8)
        }

        moreButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalTo(profileImageView)
        }
        
        mediaCollectionView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.top.equalTo(headerView.snp.bottom)
            make.height.equalTo(UIScreen.main.bounds.width * 1.2)
        }
        
        pageCountBadge.snp.makeConstraints { make in
            make.top.equalTo(mediaCollectionView.snp.top).offset(16)
            make.trailing.equalTo(mediaCollectionView.snp.trailing).offset(-16)
            make.height.equalTo(24)
            make.width.greaterThanOrEqualTo(44)
        }

        pageControl.snp.makeConstraints { make in
            pageControlHeightConstraint = make.height.equalTo(16).constraint
            make.top.equalTo(mediaCollectionView.snp.bottom).offset(6)
            make.centerX.equalToSuperview()
        }
        
        actionStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.trailing.lessThanOrEqualToSuperview().inset(16)
            make.top.equalTo(pageControl.snp.bottom).offset(6)
        }
        
        
        likeButton.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview()
        }
        
        commentButton.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview()
        }
        

        captionLabel.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(16)
            make.top.equalTo(actionStack.snp.bottom).offset(8)
        }
        
        createdLabel.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(16)
            make.top.equalTo(captionLabel.snp.bottom).offset(4)
            make.bottom.equalToSuperview().inset(16)
        }
    }
    
    override func configureView() {
        view.backgroundColor = GrayStyle.gray100.color
        navigationItem.title = "게시글"

        let editAction = UIAction(title: "수정") { [weak self] _ in
            self?.menuActionRelay.accept(.edit)
        }
        let deleteAction = UIAction(title: "삭제", attributes: .destructive) { [weak self] _ in
            self?.confirmDelete()
        }
        moreButton.menu = UIMenu(title: "", children: [editAction, deleteAction])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isAutoPlayEnabled {
            updatePlayback()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        for cell in mediaCollectionView.visibleCells {
            if let mediaCell = cell as? CommunityDetailMediaCell {
                mediaCell.stopPlayback()
            }
        }
    }
    
    override func configureBind() {
        let headerTap = UITapGestureRecognizer()
        headerView.addGestureRecognizer(headerTap)
        headerView.isUserInteractionEnabled = true

        let input = CommunityDetailViewModel.Input(
            likeTapped: likeButton.rx.tap,
            menuAction: menuActionRelay.asObservable(),
            refresh: refreshRelay.asObservable()
        )
        
        let output = viewModel.transform(input: input)
        
        mediaItemsRelay
            .bind(to: mediaCollectionView.rx.items(
                cellIdentifier: CommunityDetailMediaCell.identifier,
                cellType: CommunityDetailMediaCell.self
            )) { _, item, cell in
                cell.configure(urlString: item)
            }
            .disposed(by: disposeBag)
        
        output.postDetail
            .drive(onNext: { [weak self] dto in
                guard let self else { return }
                self.currentPostId = dto.postId
                self.onUpdated?(dto.postId)
                self.currentDetail = dto
                self.lastComments = dto.comments
                self.mediaItemsRelay.accept(dto.files)
                self.pageControl.numberOfPages = dto.files.count
                self.pageControl.currentPage = 0
                let hideIndicator = dto.files.count <= 1
                self.pageControl.isHidden = hideIndicator
                self.pageControlHeightConstraint?.update(offset: hideIndicator ? 0 : 16)
                self.updatePageBadge(current: 1, total: dto.files.count)
                self.currentMediaIndex = 0
                DispatchQueue.main.async {
                    self.updatePlayback()
                }
                
                self.nickLabel.text = dto.creator.nick
                self.currentCreatorId = dto.creator.userID
                self.createdLabel.text = dto.createdAt.toPostDetailDateString()
                self.likeCountLabel.text = self.formatCount(dto.likeCount)
                let replyCount = dto.comments.reduce(0) { $0 + $1.replies.count }
                self.commentCountLabel.text = self.formatCount(dto.comments.count + replyCount)
                
                if let profile = dto.creator.profileImage {
                    self.profileImageView.setKFImage(urlString: profile, targetSize: self.profileImageView.bounds.size)
                } else {
                    self.profileImageView.image = nil
                }
                
                let nick = dto.creator.nick + " "
                let content = dto.content
                let title = dto.title.isEmpty ? "" : dto.title + "\n"
                let category = dto.category.isEmpty ? "" : " #\(dto.category)"
                let text = nick + title + content + category
                let attr = NSMutableAttributedString(string: text, attributes: [
                    .font: UIFont.Pretendard.caption1 as Any,
                    .foregroundColor: GrayStyle.gray60.color as Any
                ])
                attr.addAttributes([
                    .font: UIFont.Pretendard.body2 as Any,
                    .foregroundColor: GrayStyle.gray30.color as Any
                ], range: NSRange(location: 0, length: nick.count))
                if !title.isEmpty {
                    let titleRange = NSRange(location: nick.count, length: title.count)
                    attr.addAttributes([
                        .font: UIFont.Pretendard.body2 as Any,
                        .foregroundColor: GrayStyle.gray30.color as Any
                    ], range: titleRange)
                }
                if !category.isEmpty {
                    let categoryRange = NSRange(location: (nick + title + content).count, length: category.count)
                    attr.addAttributes([
                        .foregroundColor: Brand.brightTurquoise.color as Any
                    ], range: categoryRange)
                }
                self.captionLabel.attributedText = attr
            })
            .disposed(by: disposeBag)
        
        output.likeState
            .drive(with: self) { owner, isLiked in
                owner.likeButton.isSelected = isLiked
            }
            .disposed(by: disposeBag)
        
        output.likeCount
            .drive(with: self) { owner, count in
                owner.likeCountLabel.text = owner.formatCount(count)
            }
            .disposed(by: disposeBag)

        output.isOwner
            .drive(with: self) { owner, isOwner in
                owner.moreButton.isHidden = !isOwner
            }
            .disposed(by: disposeBag)
        
        output.networkError
            .emit(with: self) { owner, error in
                if owner.shouldPopAfterError(error) {
                    owner.showAlert(title: "오류", message: error.errorDescription) { [weak owner] in
                        if let postId = owner?.currentPostId ?? owner?.initialPostId {
                            owner?.onDeleted?(postId)
                        }
                        owner?.navigationController?.popViewController(animated: true)
                    }
                } else {
                    owner.showAlert(title: "오류", message: error.errorDescription)
                }
            }
            .disposed(by: disposeBag)

        output.menuAction
            .emit(with: self) { owner, action in
                guard case .edit = action else { return }
                guard let detail = owner.currentDetail else { return }
                let category = searchCategoryType.allCases.first { $0.query == detail.category } ?? .all
                let seed = CommunityCreateViewModel.Seed(
                    postId: detail.postId,
                    title: detail.title,
                    content: detail.content,
                    category: category,
                    latitude: detail.geolocation.latitude,
                    longitude: detail.geolocation.longitude,
                    files: detail.files
                )
                let vm = CommunityCreateViewModel(mode: .edit(seed))
                let vc = CommunityCreateViewController(viewModel: vm)
                vc.onUpdated = { [weak owner] in
                    owner?.refreshRelay.accept(())
                }
                owner.navigationController?.pushViewController(vc, animated: true)
            }
            .disposed(by: disposeBag)

        output.deleteSuccess
            .emit(with: self) { owner, _ in
                owner.onDeleted?(owner.currentPostId ?? owner.initialPostId)
                owner.navigationController?.popViewController(animated: true)
            }
            .disposed(by: disposeBag)

        mediaCollectionView.rx.didScroll
            .bind(with: self) { owner, _ in
                let width = max(owner.mediaCollectionView.bounds.width, 1)
                let page = Int(round(owner.mediaCollectionView.contentOffset.x / width))
                let maxIndex = max(owner.mediaItemsRelay.value.count - 1, 0)
                let clamped = max(0, min(page, maxIndex))
                owner.pageControl.currentPage = clamped
                owner.updatePageBadge(current: clamped + 1, total: owner.mediaItemsRelay.value.count)
                if owner.currentMediaIndex != clamped {
                    owner.currentMediaIndex = clamped
                    owner.updatePlayback()
                }
            }
            .disposed(by: disposeBag)

        headerTap.rx.event
            .filter { $0.state == .recognized }
            .bind(with: self) { owner, _ in
                guard let creatorId = owner.currentCreatorId else { return }
                Task {
                    let currentUserId = await TokenStorage.shared.userId() ?? ""
                    if currentUserId.isEmpty { return }
                    if creatorId == currentUserId {
                        let vc = ProfileViewController()
                        owner.navigationController?.pushViewController(vc, animated: true)
                    } else {
                        let vm = UserProfileViewModel(userId: creatorId)
                        let vc = UserProfileViewController(viewModel: vm)
                        owner.navigationController?.pushViewController(vc, animated: true)
                    }
                }
            }
            .disposed(by: disposeBag)

        commentButton.rx.tap
            .bind(with: self) { owner, _ in
                guard let postId = owner.currentPostId else { return }
                let vm = CommentsViewModel(postId: postId, initialComments: owner.lastComments)
                let vc = CommentsViewController(viewModel: vm)
                vc.onCountChanged = { [weak owner] count in
                    owner?.commentCountLabel.text = owner?.formatCount(count)
                }
                vc.onCommentsChanged = { [weak owner] comments in
                    owner?.lastComments = comments
                }
                vc.onPostNotFound = { [weak owner] postId in
                    owner?.onDeleted?(postId)
                    owner?.navigationController?.popViewController(animated: true)
                }
                let nav = UINavigationController(rootViewController: vc)
                nav.modalPresentationStyle = .pageSheet
                owner.present(nav, animated: true)
            }
            .disposed(by: disposeBag)
    }
    
    private func presentMedia(urlString: String) {
        let ext = (urlString as NSString).pathExtension.lowercased()
        let isVideo = ["mp4", "mov", "avi", "mkv", "wmv", "webm"].contains(ext)
        if isVideo {
            return
        } else {
            let vc = RemoteImagePreviewViewController(imageURL: urlString)
            present(vc, animated: true)
        }
    }
}

private extension CommunityDetailViewController {
    func shouldPopAfterError(_ error: NetworkError) -> Bool {
        if case .statusCodeError(let status) = error, status == .notFound {
            return true
        }
        if case .serverError(let dto) = error {
            return dto.message == "게시글을 찾을 수 없습니다."
        }
        return false
    }

    func confirmDelete() {
        let alert = UIAlertController(title: "삭제", message: "게시글을 삭제할까요?", preferredStyle: .alert)
        let cancel = UIAlertAction(title: "취소", style: .cancel)
        let confirm = UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            self?.menuActionRelay.accept(.delete)
        }
        alert.addAction(cancel)
        alert.addAction(confirm)
        present(alert, animated: true)
    }

    func formatCount(_ value: Int) -> String {
        if value >= 1_000_000 {
            let number = Double(value) / 1_000_000
            return String(format: number.truncatingRemainder(dividingBy: 1) == 0 ? "%.0fM" : "%.1fM", number)
        }
        if value >= 1_000 {
            let number = Double(value) / 1_000
            return String(format: number.truncatingRemainder(dividingBy: 1) == 0 ? "%.0fK" : "%.1fK", number)
        }
        return "\(value)"
    }
    
    func updatePageBadge(current: Int, total: Int) {
        guard total > 1 else {
            pageCountBadge.isHidden = true
            return
        }
        pageCountBadge.isHidden = false
        pageCountBadge.text = "\(current)/\(total)"
    }
    
    func updatePlayback() {
        guard isAutoPlayEnabled else { return }
        for cell in mediaCollectionView.visibleCells {
            if let mediaCell = cell as? CommunityDetailMediaCell {
                mediaCell.stopPlayback()
            }
        }
        guard let cell = mediaCollectionView.cellForItem(at: IndexPath(item: currentMediaIndex, section: 0)) as? CommunityDetailMediaCell else {
            return
        }
        cell.startPlayback(muted: false)
    }
    
    func stopAllMediaPlayback() {
        for cell in mediaCollectionView.visibleCells {
            if let mediaCell = cell as? CommunityDetailMediaCell {
                mediaCell.stopPlayback()
            }
        }
    }
    
}

extension CommunityDetailViewController {
    func communityTransitionDestinationFrame(in containerView: UIView) -> CGRect {
        view.layoutIfNeeded()
        mediaCollectionView.layoutIfNeeded()
        return mediaCollectionView.convert(mediaCollectionView.bounds, to: containerView)
    }
    
    func communityTransitionSourceFrame(in containerView: UIView) -> CGRect {
        view.layoutIfNeeded()
        mediaCollectionView.layoutIfNeeded()
        let indexPath = IndexPath(item: currentMediaIndex, section: 0)
        if let cell = mediaCollectionView.cellForItem(at: indexPath) {
            return cell.convert(cell.bounds, to: containerView)
        }
        if let cell = mediaCollectionView.visibleCells.first {
            return cell.convert(cell.bounds, to: containerView)
        }
        return mediaCollectionView.convert(mediaCollectionView.bounds, to: containerView)
    }
    
    func communityTransitionSnapshotView() -> UIView? {
        mediaCollectionView.layoutIfNeeded()
        let indexPath = IndexPath(item: currentMediaIndex, section: 0)
        if let cell = mediaCollectionView.cellForItem(at: indexPath) as? CommunityDetailMediaCell {
            return cell.makeTransitionSnapshotView()
        }
        if let cell = mediaCollectionView.visibleCells.first as? CommunityDetailMediaCell {
            return cell.makeTransitionSnapshotView()
        }
        return mediaCollectionView.snapshotView(afterScreenUpdates: true)
    }
    
    func setCommunityTransitionMediaHidden(_ hidden: Bool) {
        mediaCollectionView.isHidden = hidden
        pageControl.isHidden = hidden || pageControl.numberOfPages <= 1
        pageCountBadge.isHidden = hidden || mediaItemsRelay.value.count <= 1
    }
    
    func setCommunityTransitionAutoPlayEnabled(_ enabled: Bool) {
        isAutoPlayEnabled = enabled
        if enabled {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
                self?.updatePlayback()
            }
        } else {
            stopAllMediaPlayback()
        }
    }
}
