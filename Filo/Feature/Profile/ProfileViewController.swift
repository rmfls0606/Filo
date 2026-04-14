//
//  ProfileViewController.swift
//  Filo
//
//  Created by 이상민 on 12/17/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

final class ProfileViewController: BaseViewController {
    private let viewModel: ProfileViewModel
    private let disposeBag = DisposeBag()
    private let hashTagsRelay = BehaviorRelay<[String]>(value: [])
    private let logoutRelay = PublishRelay<Void>()
    private var currentHashTags: [String] = []
    private let loadingIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .large)
        view.hidesWhenStopped = true
        return view
    }()
    private var isAuthenticatingChatAccess = false

    private let menuItems: [ProfileMenuCell.Item] = [
        .init(title: "내가 작성한\n필터", iconName: "camera.filters"),
        .init(title: "내가 올린\n게시글", iconName: "doc.text.image"),
        .init(title: "찜한자료", iconName: "heart"),
        .init(title: "구매내역", iconName: "bag"),
        .init(title: "설정", iconName: "gearshape")
    ]

    private let scrollView: UIScrollView = {
        let view = UIScrollView()
        view.showsVerticalScrollIndicator = true
        view.contentInset.bottom = CustomTabBarView.height + 20
        view.verticalScrollIndicatorInsets.bottom = CustomTabBarView.height + 20
        return view
    }()
    
    private let contentView = UIView()
    
    private let profileBox = UIView()
    
    private let profileImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.layer.cornerRadius = 36
        view.layer.borderWidth = 1.0
        view.layer.borderColor = GrayStyle.gray75.color?.withAlphaComponent(0.5).cgColor
        view.clipsToBounds = true
        return view
    }()
    
    private let profileChevronView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(systemName: "chevron.right")
        view.tintColor = GrayStyle.gray75.color
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    private let nameStack: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 8
        return view
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .Mulggeol.body1
        label.textColor = GrayStyle.gray30.color
        return label
    }()
    
    private let nickLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.body1
        label.textColor = GrayStyle.gray75.color
        return label
    }()
    
    private let hashTagCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 4
        layout.estimatedItemSize = .zero
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.register(TodayAuthorHashtagCollectionViewCell.self, forCellWithReuseIdentifier: TodayAuthorHashtagCollectionViewCell.identifier)
        view.showsHorizontalScrollIndicator = false
        view.contentInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        view.backgroundColor = GrayStyle.gray100.color
        return view
    }()

    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .clear
        view.isScrollEnabled = false
        view.register(ProfileMenuCell.self, forCellWithReuseIdentifier: ProfileMenuCell.identifier)
        return view
    }()
    
    private let logoutButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.cornerStyle = .capsule
//        config.baseBackgroundColor = GrayStyle.gray90.color
        config.baseForegroundColor = GrayStyle.gray45.color
        config.attributedTitle = AttributedString("로그아웃", attributes: AttributeContainer([
            .font: UIFont.Pretendard.caption1 ?? UIFont.systemFont(ofSize: 12)
        ]))
        let button = UIButton(configuration: config)
        return button
    }()

    private var hashTagHeightConstraint: Constraint?
    private var menuHeightConstraint: Constraint?
    
    private var hashtagCollectionHeight: CGFloat {
        let fallback: CGFloat = 24
        guard let font = UIFont.Pretendard.caption1 else {
            return fallback
        }
        return max(font.lineHeight + 8, fallback)
    }
    
    init(viewModel: ProfileViewModel = ProfileViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    override func configureView() {
        navigationItem.title = "PROFILE"
        navigationItem.rightBarButtonItem?.tintColor = GrayStyle.gray75.color
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "message"))
        view.backgroundColor = GrayStyle.gray100.color
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateHeights()
    }

    override func configureHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(profileBox)
        profileBox.addSubview(profileImageView)
        profileBox.addSubview(nameStack)
        profileBox.addSubview(profileChevronView)
        nameStack.addArrangedSubview(nameLabel)
        nameStack.addArrangedSubview(nickLabel)
        contentView.addSubview(hashTagCollectionView)
        contentView.addSubview(collectionView)
        contentView.addSubview(logoutButton)
        view.addSubview(loadingIndicator)
    }

    override func configureLayout() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView.frameLayoutGuide)
        }
        
        profileBox.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        
        profileImageView.snp.makeConstraints { make in
            make.verticalEdges.leading.equalToSuperview()
            make.size.equalTo(72)
        }
        
        nameStack.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(profileImageView.snp.trailing).offset(20)
            make.trailing.lessThanOrEqualTo(profileChevronView.snp.leading).offset(-8)
        }

        profileChevronView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(4)
            make.size.equalTo(16)
        }
        
        hashTagCollectionView.snp.makeConstraints { make in
            make.top.equalTo(profileBox.snp.bottom).offset(20)
            make.horizontalEdges.equalToSuperview()
            hashTagHeightConstraint = make.height.equalTo(0).constraint
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(hashTagCollectionView.snp.bottom)
            make.horizontalEdges.equalToSuperview()
            menuHeightConstraint = make.height.greaterThanOrEqualTo(120).constraint
            make.bottom.equalTo(logoutButton.snp.top).offset(-20)
        }
        
        logoutButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(20)
        }

        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    override func configureBind() {
        collectionView.rx.setDelegate(self)
            .disposed(by: disposeBag)
        
        hashTagCollectionView.rx.setDelegate(self)
            .disposed(by: disposeBag)

        let profileTap = UITapGestureRecognizer()
        profileBox.addGestureRecognizer(profileTap)
        profileBox.isUserInteractionEnabled = true
        profileTap.rx.event
            .filter { $0.state == .recognized }
            .bind(with: self) { owner, _ in
                let vc = ProfileEditViewController()
                owner.navigationController?.pushViewController(vc, animated: true)
            }
            .disposed(by: disposeBag)

        hashTagsRelay
            .bind(to: hashTagCollectionView.rx.items(
                cellIdentifier: TodayAuthorHashtagCollectionViewCell.identifier,
                cellType: TodayAuthorHashtagCollectionViewCell.self
            )) { _, tag, cell in
                cell.configure(tag)
            }
            .disposed(by: disposeBag)

        hashTagsRelay
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, tags in
                owner.currentHashTags = tags
                owner.hashTagCollectionView.isHidden = tags.isEmpty
                owner.hashTagCollectionView.collectionViewLayout.invalidateLayout()
                owner.hashTagCollectionView.reloadData()
                owner.updateHeights()
            }
            .disposed(by: disposeBag)

        let input = ProfileViewModel.Input(
            viewWillAppear: rx.methodInvoked(#selector(UIViewController.viewWillAppear(_:))).map { _ in },
            logoutTap: logoutRelay.asObservable()
        )
        
        let output = viewModel.transform(input: input)

        output.profileItem
            .drive(with: self) { owner, item in
                guard let item else { return }
                owner.nameLabel.text = item.name
                owner.nickLabel.text = item.nick
                if let profile = item.profileImage {
                    owner.profileImageView.setKFImage(urlString: profile, targetSize: owner.profileImageView.bounds.size)
                } else {
                    owner.profileImageView.image = nil
                }
                owner.hashTagsRelay.accept(item.hashTags)
            }
            .disposed(by: disposeBag)

        output.networkError
            .emit(with: self) { owner, error in
                owner.showAlert(title: "오류", message: error.errorDescription)
            }
            .disposed(by: disposeBag)
        
        output.logoutSuccess
            .emit(with: self) { owner, _ in
                owner.switchToLogin()
            }
            .disposed(by: disposeBag)

        output.isLoading
            .drive(with: self) { owner, isLoading in
                owner.logoutButton.isUserInteractionEnabled = !isLoading
                owner.navigationItem.rightBarButtonItem?.isEnabled = !isLoading
                if isLoading {
                    owner.loadingIndicator.startAnimating()
                } else {
                    owner.loadingIndicator.stopAnimating()
                }
            }
            .disposed(by: disposeBag)
        
        logoutButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.presentLogoutAlert()
            }
            .disposed(by: disposeBag)

        Observable.just(menuItems)
            .bind(to: collectionView.rx.items(
                cellIdentifier: ProfileMenuCell.identifier,
                cellType: ProfileMenuCell.self
            )) { _, item, cell in
                cell.configure(item: item)
            }
            .disposed(by: disposeBag)

        collectionView.rx.itemSelected
            .bind(with: self) { owner, indexPath in
                guard owner.menuItems.indices.contains(indexPath.item) else { return }
                let item = owner.menuItems[indexPath.item]
                if item.title.contains("필터") {
                    let vc = MyFilterListViewController()
                    owner.navigationController?.pushViewController(vc, animated: true)
                } else if item.title.contains("게시글") {
                    let vc = MyPostListViewController()
                    owner.navigationController?.pushViewController(vc, animated: true)
                } else if item.title.contains("찜한자료") {
                    let vc = LikedContentViewController()
                    owner.navigationController?.pushViewController(vc, animated: true)
                } else if item.title.contains("구매내역") {
                    let vc = PurchaseHistoryViewController()
                    owner.navigationController?.pushViewController(vc, animated: true)
                } else if item.title.contains("설정") {
                    let vc = SettingsViewController()
                    owner.navigationController?.pushViewController(vc, animated: true)
                }
            }
            .disposed(by: disposeBag)

        updateHeights()

        navigationItem.rightBarButtonItem?.rx.tap
            .compactMap{ $0 }
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.openChatListIfAuthorized()
            })
            .disposed(by: disposeBag)
    }
}

extension ProfileViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView === hashTagCollectionView {
            let font = UIFont.Pretendard.caption1 ?? UIFont.systemFont(ofSize: 12)
            guard indexPath.item < currentHashTags.count else {
                return CGSize(width: 44, height: hashtagCollectionHeight)
            }
            let raw = currentHashTags[indexPath.item]
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            let normalized = trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let display = normalized.isEmpty ? "#" : "#\(normalized)"
            let width = (display as NSString).size(withAttributes: [.font: font]).width
            return CGSize(width: ceil(width) + 32, height: hashtagCollectionHeight)
        }
        guard let layout = collectionViewLayout as? UICollectionViewFlowLayout else {
            return CGSize(width: 80, height: 80)
        }
        let inset = layout.sectionInset.left + layout.sectionInset.right
        let totalSpacing = layout.minimumInteritemSpacing * 3
        let width = (collectionView.bounds.width - inset - totalSpacing) / 4
        return CGSize(width: max(0, width), height: max(0, width))
    }
}

private extension ProfileViewController {
    func updateHeights() {
        let hashHeight: CGFloat = currentHashTags.isEmpty ? 0 : 28
        hashTagHeightConstraint?.update(offset: hashHeight)

        let columns: CGFloat = 4
        let totalSpacing = (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.minimumInteritemSpacing ?? 8
        let sectionInset = (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.sectionInset ?? .zero
        let availableWidth = collectionView.bounds.width - sectionInset.left - sectionInset.right - (totalSpacing * (columns - 1))
        let itemWidth = max(0, floor(availableWidth / columns))
        let rows = CGFloat((menuItems.count + Int(columns) - 1) / Int(columns))
        let lineSpacing = (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.minimumLineSpacing ?? 8
        let height = rows * itemWidth + max(0, rows - 1) * lineSpacing + sectionInset.top + sectionInset.bottom
        menuHeightConstraint?.update(offset: max(0, height))
        view.layoutIfNeeded()
    }
    
    func switchToLogin() {
        guard let scene = view.window?.windowScene,
              let delegate = scene.delegate as? SceneDelegate else { return }
        delegate.setRootViewController(UINavigationController(rootViewController: LoginViewController()))
    }
    
    func presentLogoutAlert() {
        let alert = UIAlertController(title: "로그아웃", message: "정말 로그아웃 하시겠어요?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "확인", style: .destructive, handler: { [weak self] _ in
            self?.logoutRelay.accept(())
        }))
        present(alert, animated: true)
    }

    func openChatListIfAuthorized() {
        let currentUserId = (try? KeychainManager.shared.read(key: .userId)) ?? ""
        let vm = ChatRoomListViewModel(currentUserId: currentUserId)
        let vc = ChatRoomListViewController(viewModel: vm)
        navigationController?.pushViewController(vc, animated: true)
    }
}
