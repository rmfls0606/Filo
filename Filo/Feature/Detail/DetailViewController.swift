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

final class DetailViewController: BaseViewController {
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
        return view
    }()
    
    private let filterImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        return view
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
        label.text = "2000".formattedDecimal() //수정
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
    
    private let metadataView = FilterImageRegisterView()
    
    private var filterValuesHeightConstraint: Constraint?
    private let filterValueItemsRelay = BehaviorRelay<[FilterValuesEntity]>(value: [])
    
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
        guard let font = UIFont.Pretendard.caption1 else {
            return 0
        }
        return font.lineHeight + 8
    }
    
    let viewModel: DetailViewModel
    
    init(viewModel: DetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateFilterValuesLayout()
    }
    
    override func configureHierarchy() {
        view.addSubview(detailScrollView)
        detailScrollView.addSubview(detailStackView)
        detailStackView.addArrangedSubview(filterImageContainer)
        filterImageContainer.addSubview(filterImageView)
        
        detailStackView.addArrangedSubview(dividerView)
        
        detailStackView.addArrangedSubview(coinContainer)
        coinContainer.addSubview(coinStackView)
        coinStackView.addArrangedSubview(coinLabel)
        coinStackView.addArrangedSubview(coinUnitLabel)
        
        detailStackView.addArrangedSubview(filterInfoContainer)
        filterInfoContainer.addSubview(filterInfoStackView)
        filterInfoStackView.addArrangedSubview(makeFilterInfoBoxView(title: "다운로드", count: 2400))
        filterInfoStackView.addArrangedSubview(makeFilterInfoBoxView(title: "찜하기", count: 800))
        
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
        authorProfileBox.addSubview(authorProfileImage)
        authorProfileBox.addSubview(authorNameStackView)
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
        
        filterImageView.snp.makeConstraints { make in
            make.top.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(filterImageView.snp.width)
            make.bottom.equalToSuperview() //수정해야함
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
        
        authorProfileImage.snp.makeConstraints { make in
            make.verticalEdges.leading.equalToSuperview()
            make.size.equalTo(72)
        }
        
        authorNameStackView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(authorProfileImage.snp.trailing).offset(20)
            make.trailing.lessThanOrEqualTo(sendMessageButton.snp.leading).inset(-20)
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
        metadataView.setReadOnlyMetadataMode()
    }
    
    override func configureBind() {
        let input = DetailViewModel.Input()
        
        let output = viewModel.transform(input: input)
        
        output.filterDetailData
            .drive(with: self){ owner, data in
                owner.navigationItem.title = data.title
                owner.filterImageView.setKFImage(urlString: data.files[0])
                owner.coinLabel.text = "\(data.price)".formattedDecimal()
                if let metadata = owner.makeMetadata(from: data) {
                    owner.metadataView.applyMetadata(metadata)
                }else{
                    owner.metadataView.showEmptyMetadata()
                }
                owner.downloadCheck(data.isDownloaded)
                //creator
                if let urlString = data.creator.profileImage{
                    owner.authorProfileImage.setKFImage(urlString: urlString)
                }
                
                owner.authorName.text = data.creator.name
                owner.authorNickname.text = data.creator.nick
                owner.authorDescriptionLabel.text = data.creator.introduction
            }
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
        
        navigationItem.leftBarButtonItem?.rx.tap
            .bind(with: self, onNext: { owner, _ in
                owner.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    private func makeFilterInfoBoxView(title: String, count: Int = 0) -> UIView{
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
        
        let contentCountLabel: UILabel = {
            let label = UILabel()
            label.text = formattedCount(count)
            label.font = .Pretendard.title1
            label.textColor = GrayStyle.gray30.color
            return label
        }()
        
        infoContainer.addSubview(infoStackView)
        infoStackView.addArrangedSubview(contentTitleLabel)
        infoStackView.addArrangedSubview(contentCountLabel)

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
        let columns: CGFloat = 6
        let padding: CGFloat = 20.0
        let totalSpacing = layout.minimumInteritemSpacing * (columns - 1)
        let availableWidth = filterValuesCollectionView.bounds.width - totalSpacing - (2 * padding)
        let itemWidth = floor(availableWidth / columns)
        let labelHeight = UIFont.Pretendard.body2?.lineHeight ?? 16
        let itemHeight = 32 + 6 + labelHeight
        layout.itemSize = CGSize(width: itemWidth, height: itemHeight)
        let rows = ceil(CGFloat(filterValueItemsRelay.value.count) / columns)
        let totalHeight = rows * itemHeight + max(0, rows - 1) * layout.minimumLineSpacing + (2 * padding)
        filterValuesHeightConstraint?.update(offset: totalHeight)
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
        guard let meta = dto.photometadata else { return nil }
        let (make, model) = splitCamera(meta.camera)
        let lensModel = meta.lensInfo.isEmpty ? nil : meta.lensInfo
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
