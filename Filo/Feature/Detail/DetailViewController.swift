//
//  DetailViewController.swift
//  Filo
//
//  Created by 이상민 on 1/25/26.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class DetailViewController: BaseViewController, UICollectionViewDelegateFlowLayout {
    //MARK: - Properties
    private let disposeBag = DisposeBag()
    override var prefersCustomTabBarHidden: Bool{
        return true
    }
    
    //MARK: - UI
    private let detailScrollView: UIScrollView = {
        let view = UIScrollView()
        view.showsVerticalScrollIndicator = false
        return view
    }()
    
    private let detailStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 20
        return view
    }()
    
    private let filterImageContainer: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()
    
    private let originalImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let filteredImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let compareHandleStackView: UIStackView = {
        let view = UIStackView()
        view.backgroundColor = .clear
        view.spacing = 8
        view.axis = .horizontal
        view.alignment = .center
        return view
    }()
    
    private let compareAfterLabelBox: UIView = {
        let view = UIView()
        view.backgroundColor = GrayStyle.gray75.color?.withAlphaComponent(0.5)
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let compareAfterLabel: UILabel = {
        let label = UILabel()
        label.text = "After"
        label.font = .Pretendard.caption2
        label.textAlignment = .center
        label.textColor = GrayStyle.gray60.color
        return label
    }()
    
    private let compareBeforeBox: UIView = {
        let view = UIView()
        view.backgroundColor = GrayStyle.gray75.color?.withAlphaComponent(0.5)
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let compareBeforeLabel: UILabel = {
        let label = UILabel()
        label.text = "Before"
        label.font = .Pretendard.caption2
        label.textAlignment = .center
        label.textColor = GrayStyle.gray60.color
        return label
    }()
    
    private let compareDragButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .capsule
        var imageConfig = UIImage.SymbolConfiguration(pointSize: 8)
        config.preferredSymbolConfigurationForImage = imageConfig
        config.image = UIImage(systemName: "arrowtriangle.up.fill")
        config.baseForegroundColor = GrayStyle.gray60.color
        config.baseBackgroundColor = GrayStyle.gray75.color?.withAlphaComponent(0.5)
        config.cornerStyle = .capsule
        config.background.strokeWidth = 2.0
        config.background.strokeColor = GrayStyle.gray75.color
        let button = UIButton(configuration: config)
        button.contentMode = .scaleAspectFit
        return button
    }()
    
    private let dividerView: UIView = {
        let view = UIView()
        view.backgroundColor = Brand.deepTurquoise.color
        return view
    }()
    
    private let coinContainer: UIView = {
        let view = UIView()
        return view
    }()
    
    private let coinStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.spacing = 8
        view.alignment = .bottom
        view.distribution = .fill
        return view
    }()
    
    private let coinLabel: UILabel = {
        let label = UILabel()
        label.text = "-"
        label.font = .Mulggeol.title1
        label.textColor = GrayStyle.gray30.color
        return label
    }()
    
    private let coinUnitLabel: UILabel = {
        let label = UILabel()
        label.text = "Coin"
        label.font = .Mulggeol.body1
        label.textColor = GrayStyle.gray75.color
        return label
    }()
    
    private let filterInfoContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let filterInfoStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.spacing = 8
        view.distribution = .fillEqually
        view.alignment = .center
        return view
    }()
    
    private let downloadCountLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.title1
        label.textColor = GrayStyle.gray30.color
        label.text = "0"
        return label
    }()
    
    private let likeCountLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.title1
        label.textColor = GrayStyle.gray30.color
        label.text = "0"
        return label
    }()
    
    private let metadataView = FilterImageRegisterView()
    
    private var filterValuesHeightConstraint: Constraint?
    private let filterValueItemsRelay = BehaviorRelay<[FilterValuesEntity]>(value: [])
    
    private var compareHandleCenterXConstraint: Constraint?
    private var compareProgress: CGFloat = 0.5
    
    private let filterPresetContainer: UIView = {
        let view = UIView()
        view.backgroundColor = Brand.blackTurquoise.color
        view.layer.borderWidth = 2.0
        view.layer.borderColor = Brand.blackTurquoise.color?.cgColor
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        return view
    }()
    
    private let filterPresetHeader: UIView = {
        let view = UIView()
        view.backgroundColor = GrayStyle.gray100.color
        return view
    }()
    
    private let filterPresetTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Filter Presets"
        label.font = .Pretendard.caption1
        label.textColor = Brand.deepTurquoise.color
        return label
    }()
    
    private let lutTitleLable: UILabel = {
        let label = UILabel()
        label.text = "LUT"
        label.font = .Pretendard.caption1
        label.textColor = Brand.deepTurquoise.color
        return label
    }()
    
    private lazy var filterValuesCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 20
        layout.minimumLineSpacing = 16
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .clear
        view.isScrollEnabled = false
        view.contentInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        view.register(FilterValueCollectionViewCell.self, forCellWithReuseIdentifier: FilterValueCollectionViewCell.identifier)
        return view
    }()
    
    private let filterValuesBlurView: UIVisualEffectView = {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterialLight))
        view.isHidden = false
        view.alpha = 0.96
        view.scalesLargeContentImage = true
        return view
    }()
    
    private let filterValuesOverlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.176, green: 0.188, blue: 0.192, alpha: 0.9)
        return view
    }()
    
    private let filterValuesLockStack: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 16
        view.alignment = .center
        return view
    }()
    
    private let filterValuesLockIcon: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(systemName: "lock.fill")
        view.tintColor = GrayStyle.gray45.color
        return view
    }()
    
    private let filterValuesLockLabel: UILabel = {
        let label = UILabel()
        label.text = "결제가 필요한 유료 필터입니다"
        label.font = .Pretendard.body1
        label.textColor = GrayStyle.gray45.color
        label.textAlignment = .center
        return label
    }()
    
    private let buyButton: UIButton = {
        let btn = UIButton()
        btn.setTitle("결제하기", for: .normal)
        btn.titleLabel?.font = .Pretendard.title1
        btn.backgroundColor = Brand.brightTurquoise.color
        btn.layer.cornerRadius = 12
        btn.clipsToBounds = true
        btn.setTitleColor(.white, for: .normal)
        return btn
    }()
    
    private let secondDivider: UIView = {
        let view = UIView()
        view.backgroundColor = Brand.deepTurquoise.color
        return view
    }()
    
    private let authorIntroductionStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 20
        return view
    }()
    
    private let authorProfileBox: UIView = {
        let view = UIView()
        return view
    }()
    
    private let authorBox: UIView = {
        let view = UIView()
        return view
    }()
    
    private let authorProfileImage: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.layer.cornerRadius = 36
        view.layer.borderWidth = 1.0
        view.layer.borderColor = GrayStyle.gray75.color?.withAlphaComponent(0.5).cgColor
        view.clipsToBounds = true
        return view
    }()
    
    private let authorNameStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 8
        return view
    }()
    
    private let authorName: UILabel = {
        let label = UILabel()
        label.font = .Mulggeol.body1
        label.textColor = GrayStyle.gray30.color
        return label
    }()
    
    private let authorNickname: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.body1
        label.textColor = GrayStyle.gray75.color
        return label
    }()
    
    private let sendMessageButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(named: "message")
        config.baseForegroundColor = GrayStyle.gray30.color
        config.baseBackgroundColor = Brand.deepTurquoise.color
        config.background.cornerRadius = 12
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)
        
        let button = UIButton(configuration: config)
        return button
    }()
    
    private lazy var hashtagCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 4
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.register(TodayAuthorHashtagCollectionViewCell.self, forCellWithReuseIdentifier: TodayAuthorHashtagCollectionViewCell.identifier)
        view.showsHorizontalScrollIndicator = false
        return view
    }()
    
    private let authorDescriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.caption1
        label.textColor = GrayStyle.gray60.color
        label.numberOfLines = 0
        return label
    }()
    
    private var hashtagCollectionHeight: CGFloat {
        let font = UIFont.Pretendard.caption1 ?? UIFont.systemFont(ofSize: 12)
        return font.lineHeight + 8
    }
    private var currentHashTags: [String] = []
    
    let comparePan = UIPanGestureRecognizer()
    let tapGesutre = UITapGestureRecognizer()
    let viewModel: DetailViewModel
    
    init(viewModel: DetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateFilterValuesLayout()
        updateCompareMask()
    }
    
    override func configureHierarchy() {
        view.addSubview(detailScrollView)
        detailScrollView.addSubview(detailStackView)
        detailStackView.addArrangedSubview(filterImageContainer)
        filterImageContainer.addSubview(originalImageView)
        filterImageContainer.addSubview(filteredImageView)
        filterImageContainer.addSubview(compareHandleStackView)
        compareHandleStackView.addArrangedSubview(compareAfterLabelBox)
        compareAfterLabelBox.addSubview(compareAfterLabel)
        compareHandleStackView.addArrangedSubview(compareDragButton)
        compareHandleStackView.addArrangedSubview(compareBeforeBox)
        compareBeforeBox.addSubview(compareBeforeLabel)
        
        detailStackView.addArrangedSubview(dividerView)
        
        detailStackView.addArrangedSubview(coinContainer)
        coinContainer.addSubview(coinStackView)
        coinStackView.addArrangedSubview(coinLabel)
        coinStackView.addArrangedSubview(coinUnitLabel)
        
        detailStackView.addArrangedSubview(filterInfoContainer)
        filterInfoContainer.addSubview(filterInfoStackView)
        filterInfoStackView.addArrangedSubview(makeFilterInfoBoxView(title: "다운로드", countLabel: downloadCountLabel))
        filterInfoStackView.addArrangedSubview(makeFilterInfoBoxView(title: "찜하기", countLabel: likeCountLabel))
        
        detailStackView.addArrangedSubview(metadataView)
        
        detailStackView.addArrangedSubview(filterPresetContainer)
        filterPresetContainer.addSubview(filterPresetHeader)
        filterPresetHeader.addSubview(filterPresetTitleLabel)
        filterPresetHeader.addSubview(lutTitleLable)
        filterPresetContainer.addSubview(filterValuesCollectionView)
        filterPresetContainer.addSubview(filterValuesBlurView)
        filterValuesBlurView.contentView.addSubview(filterValuesOverlayView)
        filterValuesBlurView.contentView.addSubview(filterValuesLockStack)
        filterValuesLockStack.addArrangedSubview(filterValuesLockIcon)
        filterValuesLockStack.addArrangedSubview(filterValuesLockLabel)
        
        detailStackView.addArrangedSubview(buyButton)
        
        detailStackView.addArrangedSubview(secondDivider)
        
        detailStackView.addArrangedSubview(authorIntroductionStackView)
        authorIntroductionStackView.addArrangedSubview(authorProfileBox)
        authorProfileBox.addSubview(authorBox)
        authorBox.addSubview(authorProfileImage)
        authorBox.addSubview(authorNameStackView)
        authorNameStackView.addArrangedSubview(authorName)
        authorNameStackView.addArrangedSubview(authorNickname)
        authorProfileBox.addSubview(sendMessageButton)
        authorIntroductionStackView.addArrangedSubview(hashtagCollectionView)
        authorIntroductionStackView.addArrangedSubview(authorDescriptionLabel)
    }
    
    override func configureLayout() {
        detailScrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        detailStackView.snp.makeConstraints { make in
            make.edges.equalTo(detailScrollView.contentLayoutGuide)
            make.width.equalTo(detailScrollView.frameLayoutGuide)
        }
        
        filterImageContainer.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
        }
        
        originalImageView.snp.makeConstraints { make in
            make.top.horizontalEdges.equalToSuperview().inset(20)
            make.size.equalTo(originalImageView.snp.width)
        }
        
        filteredImageView.snp.makeConstraints { make in
            make.edges.equalTo(originalImageView)
        }
        
        compareHandleStackView.snp.makeConstraints { make in
            make.top.equalTo(originalImageView.snp.bottom).offset(16)
            compareHandleCenterXConstraint = make.centerX.equalTo(originalImageView).constraint
            make.height.equalTo(24)
            make.bottom.equalToSuperview()
        }
        
        compareAfterLabel.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview().inset(2)
            make.horizontalEdges.equalToSuperview().inset(8)
        }
        
        compareDragButton.snp.makeConstraints { make in
            make.size.equalTo(24)
        }
        
        compareBeforeLabel.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview().inset(2)
            make.horizontalEdges.equalToSuperview().inset(8)
        }
        
        compareAfterLabelBox.snp.makeConstraints { make in
            make.height.equalTo(24)
        }
        
        compareBeforeBox.snp.makeConstraints { make in
            make.height.equalTo(24)
        }
        
        compareAfterLabelBox.snp.makeConstraints { make in
            make.width.equalTo(compareBeforeBox)
        }
        
        dividerView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(1)
        }
        
        coinContainer.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        
        coinStackView.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview()
            make.leading.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
        }
        
        filterInfoContainer.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        
        filterInfoStackView.snp.makeConstraints { make in
            make.verticalEdges.leading.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
        }
        
        metadataView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        
        filterPresetContainer.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        
        filterPresetHeader.snp.makeConstraints { make in
            make.top.horizontalEdges.equalToSuperview()
        }
        
        filterPresetTitleLabel.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview().inset(8)
            make.leading.equalToSuperview().inset(12)
        }
        
        lutTitleLable.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview().inset(8)
            make.trailing.equalToSuperview().inset(12)
        }
        
        filterValuesCollectionView.snp.makeConstraints { make in
            make.top.equalTo(filterPresetHeader.snp.bottom)
            make.horizontalEdges.bottom.equalToSuperview()
            make.bottom.equalToSuperview()
            filterValuesHeightConstraint = make.height.equalTo(0).constraint
        }
        
        filterValuesBlurView.snp.makeConstraints { make in
            make.edges.equalTo(filterValuesCollectionView)
        }
        
        filterValuesOverlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        filterValuesLockStack.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        buyButton.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(46)
        }
        
        secondDivider.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(1)
        }
        
        authorIntroductionStackView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(20)
            make.bottom.equalToSuperview()
        }
        
        authorProfileBox.snp.makeConstraints { make in
            make.top.horizontalEdges.equalToSuperview()
        }
        
        authorBox.snp.makeConstraints { make in
            make.verticalEdges.leading.equalToSuperview()
            make.trailing.lessThanOrEqualTo(sendMessageButton.snp.leading).inset(-20)
        }
        
        authorProfileImage.snp.makeConstraints { make in
            make.verticalEdges.leading.equalToSuperview()
            make.size.equalTo(72)
        }
        
        authorNameStackView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(authorProfileImage.snp.trailing).offset(20)
            make.trailing.equalToSuperview()
        }
        
        sendMessageButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview()
        }
        
        hashtagCollectionView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(hashtagCollectionHeight)
        }
        
        authorDescriptionLabel.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
        }
    }
    
    override func configureView() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: .likeEmpty)
        navigationItem.rightBarButtonItem?.tintColor = GrayStyle.gray75.color
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: .chevron)
        navigationItem.leftBarButtonItem?.tintColor = GrayStyle.gray75.color
        compareDragButton.addGestureRecognizer(comparePan)
        metadataView.setReadOnlyMetadataMode()
        authorBox.addGestureRecognizer(tapGesutre)
    }
    
    override func configureBind() {
        let input = DetailViewModel.Input(
            likeTapped: navigationItem.rightBarButtonItem?.rx.tap
        )
        
        let output = viewModel.transform(input: input)
        
        output.filterDetailData
            .drive(with: self){ owner, data in
                owner.navigationItem.title = data.title
                owner.filterImageContainer.alpha = 0
                let group = DispatchGroup()
                group.enter()
                owner.originalImageView.setKFImage(urlString: data.files[0]) { _ in
                    group.leave()
                }
                group.enter()
                owner.filteredImageView.setKFImage(urlString: data.files[1]) { _ in
                    group.leave()
                }
                group.notify(queue: .main) {
                    owner.filterImageContainer.alpha = 1
                    owner.updateCompareMask()
                }
                owner.coinLabel.text = "\(data.price)".formattedDecimal()
                if let metadata = owner.makeMetadata(from: data) {
                    owner.metadataView.applyMetadata(metadata)
                }else{
                    owner.metadataView.showEmptyMetadata()
                }
                owner.downloadCheck(data.isDownloaded)
                owner.downloadCountLabel.text = owner.formattedCount(data.buyerCount)
                owner.likeCountLabel.text = owner.formattedCount(data.likeCount)
                //creator
                if let urlString = data.creator.profileImage{
                    owner.authorProfileImage.setKFImage(urlString: urlString)
                }
                
                owner.coinLabel.text = data.price.formattedDecimal()
                owner.authorName.text = data.creator.name
                owner.authorNickname.text = data.creator.nick
                owner.authorDescriptionLabel.text = data.creator.introduction
            }
            .disposed(by: disposeBag)

        output.likeState
            .drive(with: self) { owner, state in
                owner.navigationItem.rightBarButtonItem?.image = state ? UIImage(named: "like_Fill") : UIImage(named: "like_Empty")
            }
            .disposed(by: disposeBag)

        output.likeCount
            .drive(with: self) { owner, count in
                owner.likeCountLabel.text = owner.formattedCount(count)
            }
            .disposed(by: disposeBag)
        
        output.creatorHashTags
            .drive(with: self) { owner, tags in
                owner.currentHashTags = tags
                owner.hashtagCollectionView.collectionViewLayout.invalidateLayout()
                owner.hashtagCollectionView.reloadData()
            }
            .disposed(by: disposeBag)

        hashtagCollectionView.rx.setDelegate(self)
            .disposed(by: disposeBag)

        output.creatorHashTags
            .drive(hashtagCollectionView.rx.items(
                cellIdentifier: TodayAuthorHashtagCollectionViewCell.identifier,
                cellType: TodayAuthorHashtagCollectionViewCell.self
            )) { _, element, cell in
                cell.configure(element)
            }
            .disposed(by: disposeBag)

        output.filterValueItems
            .drive(with: self) { owner, items in
                owner.filterValueItemsRelay.accept(items)
                owner.updateFilterValuesLayout()
            }
            .disposed(by: disposeBag)

        output.filterValueItems
            .drive(filterValuesCollectionView.rx.items(
                cellIdentifier: FilterValueCollectionViewCell.identifier,
                cellType: FilterValueCollectionViewCell.self
            )) { _, item, cell in
                cell.configure(iconName: item.iconName, valueText: item.valueText)
            }
            .disposed(by: disposeBag)

        comparePan.rx.event
            .observe(on: MainScheduler.instance)
            .subscribe(with: self, onNext: { owner, gesture in
                let location = gesture.location(in: owner.originalImageView)
                let width = owner.originalImageView.bounds.width
                guard width > 0 else { return }
                let clampedX = min(max(location.x, 0), width)
                owner.compareProgress = clampedX / width
                owner.updateCompareMask()
            })
            .disposed(by: disposeBag)
        
        navigationItem.leftBarButtonItem?.rx.tap
            .bind(with: self, onNext: { owner, _ in
                owner.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
        
        tapGesutre.rx.event
            .withLatestFrom(output.filterDetailData)
            .map{ $0.creator.userID }
            .bind(with: self) { owner, userId in
                let vm = UserProfileViewModel(userId: userId)
                let vc = UserProfileViewController(viewModel: vm)
                owner.navigationController?.pushViewController(vc, animated: true)
            }
            .disposed(by: disposeBag)

        output.networkError
            .emit(onNext: { [weak self] error in
                self?.showAlert(title: "오류", message: error.errorDescription)
            })
            .disposed(by: disposeBag)
    }
    
    private func makeFilterInfoBoxView(title: String, countLabel: UILabel) -> UIView{
        let infoContainer: UIView = {
            let view = UIView()
            view.backgroundColor = Brand.blackTurquoise.color
            view.layer.cornerRadius = 12
            return view
        }()
        
        let infoStackView: UIStackView = {
            let view = UIStackView()
            view.axis = .vertical
            view.spacing = 4
            view.alignment = .center
            return view
        }()
        
        let contentTitleLabel: UILabel = {
            let label = UILabel()
            label.text = title
            label.font = .Pretendard.caption1
            label.textColor = GrayStyle.gray75.color
            return label
        }()
        
        infoContainer.addSubview(infoStackView)
        infoStackView.addArrangedSubview(contentTitleLabel)
        infoStackView.addArrangedSubview(countLabel)

        infoStackView.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview().inset(8)
            make.horizontalEdges.equalToSuperview().inset(16)
        }
        
        return infoContainer
    }

    private func formattedCount(_ count: Int) -> String {
        if count <= 1_000 {
            return "\(count)"
        } else if count < 10_000 {
            let prefix = String(count).prefix(2)
            return "\(prefix)00+"
        } else if count < 100_000_000 {
            let man = count / 10_000
            return "\(man)만+"
        } else if count < 1_000_000_000_000 {
            let eok = count / 100_000_000
            return "\(eok)억+"
        } else {
            let jo = count / 1_000_000_000_000
            return "\(jo)조+"
        }
    }

    private func updateFilterValuesLayout() {
        guard let layout = filterValuesCollectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        let boundsWidth = filterValuesCollectionView.bounds.width
        guard boundsWidth > 0 else { return }
        let columns: CGFloat = 6
        let padding: CGFloat = 20.0
        let totalSpacing = layout.minimumInteritemSpacing * (columns - 1)
        let availableWidth = max(0, boundsWidth - totalSpacing - (2 * padding))
        let itemWidth = floor(availableWidth / columns)
        guard itemWidth > 0 else { return }
        let labelHeight = UIFont.Pretendard.body2?.lineHeight ?? 16
        let itemHeight = 32 + 6 + labelHeight
        layout.itemSize = CGSize(width: itemWidth, height: itemHeight)
        let rows = ceil(CGFloat(filterValueItemsRelay.value.count) / columns)
        let totalHeight = rows * itemHeight + max(0, rows - 1) * layout.minimumLineSpacing + (2 * padding)
        filterValuesHeightConstraint?.update(offset: totalHeight)
    }
    
    private func updateCompareMask() {
        let width = originalImageView.bounds.width
        let height = originalImageView.bounds.height
        guard width > 0 && height > 0 else { return }

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        let x = width * compareProgress
        let maskLayer: CALayer
        if let existing = filteredImageView.layer.mask {
            maskLayer = existing
        } else {
            maskLayer = CALayer()
            maskLayer.backgroundColor = UIColor.black.cgColor
            filteredImageView.layer.mask = maskLayer
        }
        maskLayer.frame = CGRect(x: 0, y: 0, width: x, height: height)
        
        let halfHandle = max(compareDragButton.bounds.width / 2.0, 0)
        let clampedHandleX = min(max(x, halfHandle), width - halfHandle)
        let offset = clampedHandleX - (width / 2.0)
        compareHandleCenterXConstraint?.update(offset: offset)
        filterImageContainer.layoutIfNeeded()

        let fadeStart: CGFloat = 0.08
        let fadeEnd: CGFloat = 0.18
        let leftAlpha = clamp((compareProgress - fadeStart) / (fadeEnd - fadeStart))
        let rightAlpha = clamp(((1.0 - compareProgress) - fadeStart) / (fadeEnd - fadeStart))
        compareAfterLabelBox.alpha = leftAlpha
        compareBeforeBox.alpha = rightAlpha

        CATransaction.commit()
    }

    private func clamp(_ value: CGFloat) -> CGFloat {
        min(max(value, 0.0), 1.0)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard collectionView === hashtagCollectionView else { return .zero }
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

    private func downloadCheck(_ isDownload: Bool) {
        filterValuesBlurView.isHidden = isDownload
        if isDownload{
            buyButton.setTitle("구매완료", for: .normal)
            buyButton.backgroundColor = GrayStyle.gray90.color
            buyButton.setTitleColor(GrayStyle.gray75.color, for: .normal)
        }else{
            buyButton.setTitle("결제하기", for: .normal)
            buyButton.backgroundColor = Brand.brightTurquoise.color
            buyButton.setTitleColor(GrayStyle.gray30.color, for: .normal)
        }
        buyButton.isUserInteractionEnabled = !isDownload
    }
    
    private func makeMetadata(from dto: FilterResponseDTO) -> FilterImageMetadata? {
        guard let meta = dto.photoMetadata else { return nil }
        let (make, model) = splitCamera(meta.camera)
        let lensModel = ((meta.lensInfo?.isEmpty) != nil) ? nil : meta.lensInfo
        let megaPixel: Double?
        if let width = meta.pixelWidth, let height = meta.pixelHeight {
            megaPixel = Double(width * height) / 1_000_000.0
        } else {
            megaPixel = nil
        }
        let fileSizeMB = meta.fileSize.map { fileSizeString(fromBytes: Int($0)) }
        return FilterImageMetadata(
            make: make,
            model: model,
            lensModel: lensModel,
            focalLength: meta.focalLength,
            fNumber: meta.aperture,
            iso: meta.iso,
            megaPixel: megaPixel,
            width: meta.pixelWidth,
            height: meta.pixelHeight,
            fileSizeMB: fileSizeMB,
            fileSizeBytes: meta.fileSize,
            format: meta.format,
            dateTimeOriginal: meta.dateTimeOriginal,
            shutterSpeed: meta.shutterSpeed,
            latitude: meta.latitude,
            longitude: meta.longitude,
            address: nil
        )
    }
    
    private func splitCamera(_ camera: String?) -> (String?, String?) {
        guard let camera, !camera.isEmpty else { return (nil, nil) }
        if let space = camera.firstIndex(of: " ") {
            let make = String(camera[..<space])
            let model = String(camera[camera.index(after: space)...])
            return (make, model)
        }
        return (nil, camera)
    }
    
    private func fileSizeString(fromBytes byteCount: Int) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(byteCount), countStyle: .file)
    }
}
