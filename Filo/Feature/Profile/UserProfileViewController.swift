//
//  UserProfileViewController.swift
//  Filo
//
//  Created by 이상민 on 2/2/26.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class UserProfileViewController: BaseViewController {
    private let scrollView: UIScrollView = {
        let view = UIScrollView()
        view.showsVerticalScrollIndicator = true
        view.contentInset.bottom = CustomTabBarView.height + 20
        view.verticalScrollIndicatorInsets.bottom = CustomTabBarView.height + 20
        return view
    }()
    
    private let userIntroductionStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 20
        return view
    }()
    //MARK: - UI
    private let userProfileBox: UIView = {
        let view = UIView()
        return view
    }()
    
    private let userProfileImage: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.layer.cornerRadius = 36
        view.layer.borderWidth = 1.0
        view.layer.borderColor = GrayStyle.gray75.color?.withAlphaComponent(0.5).cgColor
        view.clipsToBounds = true
        return view
    }()
    
    private let userNameStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 8
        return view
    }()
    
    private let userName: UILabel = {
        let label = UILabel()
        label.font = .Mulggeol.body1
        label.textColor = GrayStyle.gray30.color
        return label
    }()
    
    private let userNickname: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.body1
        label.textColor = GrayStyle.gray75.color
        return label
    }()
    
    private let chatButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(named: "message")
        config.baseForegroundColor = GrayStyle.gray30.color
        config.baseBackgroundColor = Brand.deepTurquoise.color
        config.background.cornerRadius = 12
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)
        
        let button = UIButton(configuration: config)
        return button
    }()
    
    private let hashTagCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 4
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.register(TodayAuthorHashtagCollectionViewCell.self, forCellWithReuseIdentifier: TodayAuthorHashtagCollectionViewCell.identifier)
        view.showsHorizontalScrollIndicator = false
        view.contentInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        return view
    }()

    private let segmentContainerView: UIView = {
        let view = UIView()
        return view
    }()

    private let segmentStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.distribution = .fillEqually
        view.spacing = 0
        return view
    }()

    private let leftSegmentButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("필터", for: .normal)
        button.titleLabel?.font = .Pretendard.body1
        button.tag = 0
        return button
    }()

    private let rightSegmentButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("게시글", for: .normal)
        button.titleLabel?.font = .Pretendard.body1
        button.tag = 1
        return button
    }()

    private let segmentBottomBorderView: UIView = {
        let view = UIView()
        view.backgroundColor = Brand.deepTurquoise.color
        return view
    }()

    private let segmentIndicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = Brand.brightTurquoise.color
        return view
    }()

    private let filterCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 8
        layout.minimumInteritemSpacing = 8
        let width = (UIScreen.main.bounds.width - (2 * 8.0) - (2 * 20.0)) / 3
        layout.itemSize = CGSize(width: width, height: width)
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.isScrollEnabled = false
        view.register(TodayAuthorImageCollectionViewCell.self, forCellWithReuseIdentifier: TodayAuthorImageCollectionViewCell.identifier)
        return view
    }()

    private let emptyBackgroundLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.caption1
        label.textColor = GrayStyle.gray60.color
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    //MARK: - Properties
    private let viewModel: UserProfileViewModel
    private let disposeBag = DisposeBag()
    private var filterCollectionHeightConstraint: Constraint?
    private var currentSelectedIndex: Int = 0
    private var segmentIndicatorLeadingConstraint: Constraint?
    private var currentHashTags: [String] = []
    
    private var hashtagCollectionHeight: CGFloat{
        let fallback: CGFloat = 24
        guard let font = UIFont.Pretendard.caption1 else {
            return fallback
        }
        return max(font.lineHeight + 8, fallback)
    }
    
    init(viewModel: UserProfileViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    override func configureHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(userIntroductionStackView)
        userIntroductionStackView.addArrangedSubview(userProfileBox)
        userProfileBox.addSubview(userProfileImage)
        userProfileBox.addSubview(userNameStackView)
        userNameStackView.addArrangedSubview(userName)
        userNameStackView.addArrangedSubview(userNickname)
        userProfileBox.addSubview(chatButton)
        
        userIntroductionStackView.addArrangedSubview(hashTagCollectionView)
        userIntroductionStackView.addArrangedSubview(segmentContainerView)
        segmentContainerView.addSubview(segmentStackView)
        segmentStackView.addArrangedSubview(leftSegmentButton)
        segmentStackView.addArrangedSubview(rightSegmentButton)
        segmentContainerView.addSubview(segmentBottomBorderView)
        segmentContainerView.addSubview(segmentIndicatorView)
        scrollView.addSubview(filterCollectionView)
    }
    
    override func configureLayout() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        userIntroductionStackView.snp.makeConstraints { make in
            make.top.horizontalEdges.equalToSuperview()
            make.width.equalTo(scrollView.frameLayoutGuide)
        }
        
        userProfileBox.snp.makeConstraints { make in
            make.top.horizontalEdges.equalToSuperview().inset(20)
        }
        
        userProfileImage.snp.makeConstraints { make in
            make.verticalEdges.leading.equalToSuperview()
            make.size.equalTo(72)
        }
        
        userNameStackView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(userProfileImage.snp.trailing).offset(20)
        }
        
        chatButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(userNameStackView.snp.trailing).offset(20)
            make.trailing.equalToSuperview().inset(20)
        }
        
        hashTagCollectionView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(hashtagCollectionHeight)
        }

        segmentContainerView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(44)
        }

        segmentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        segmentBottomBorderView.snp.makeConstraints { make in
            make.horizontalEdges.bottom.equalToSuperview()
            make.height.equalTo(1)
        }

        segmentIndicatorView.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.height.equalTo(2)
            make.width.equalTo(segmentContainerView.snp.width).multipliedBy(0.5)
            segmentIndicatorLeadingConstraint = make.leading.equalToSuperview().constraint
        }

        filterCollectionView.snp.makeConstraints { make in
            make.top.equalTo(segmentContainerView.snp.bottom).offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
            filterCollectionHeightConstraint = make.height.equalTo(0).constraint
            make.bottom.equalToSuperview()
        }

    }
    
    override func configureView() {
        navigationItem.title = "PROFILE"
        updateSegmentSelection(selectedIndex: 0, animated: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateSegmentSelection(selectedIndex: currentSelectedIndex, animated: false)
        if filterCollectionView.backgroundView != nil {
            let minHeight = minimumFilterHeight()
            let contentHeight = filterCollectionView.collectionViewLayout.collectionViewContentSize.height
            filterCollectionHeightConstraint?.update(offset: max(contentHeight, minHeight))
            filterCollectionView.backgroundView?.frame = filterCollectionView.bounds
        }
    }
    
    override func configureBind() {
        let selectedSegment = Observable.merge(
            leftSegmentButton.rx.tap.map { 0 },
            rightSegmentButton.rx.tap.map { 1 }
        )
        .distinctUntilChanged()

        let input = UserProfileViewModel.Input(selectedSegment: selectedSegment)
        
        let output = viewModel.transform(input: input)
        
        output.profileItem
            .drive(with: self) { owner, item in
                guard let item else { return }
                if let urlString = item.profileImage {
                    owner.userProfileImage.setKFImage(urlString: urlString)
                }
                owner.userName.text = item.name
                owner.userNickname.text = item.nick
            }
            .disposed(by: disposeBag)

        let hashTags = output.profileItem
            .map { $0?.hashTags ?? [] }

        hashTags
            .drive(with: self) { owner, tags in
                owner.currentHashTags = tags
                owner.hashTagCollectionView.collectionViewLayout.invalidateLayout()
                owner.hashTagCollectionView.reloadData()
            }
            .disposed(by: disposeBag)

        hashTags
            .drive(hashTagCollectionView.rx.items(
                cellIdentifier: TodayAuthorHashtagCollectionViewCell.identifier,
                cellType: TodayAuthorHashtagCollectionViewCell.self
            )) { _, element, cell in
                cell.configure(element)
            }
            .disposed(by: disposeBag)

        output.selectedSegment
            .drive(onNext: { [weak self] index in
                guard let self else { return }
                self.currentSelectedIndex = index
                self.updateSegmentSelection(selectedIndex: index, animated: true)
            })
            .disposed(by: disposeBag)

        output.networkError
            .emit(onNext: { [weak self] error in
                self?.showAlert(title: "오류", message: error.errorDescription)
            })
            .disposed(by: disposeBag)
        
        let visibleItems = Driver
            .combineLatest(output.userFilterItems, output.userCommunityItems, output.selectedSegment)
            .map { (filterItems: [FilterSummaryResponseDTO], communityItems: [PostSummaryResponseDTO], selected: Int) -> [String] in
                if selected == 0 {
                    return filterItems.compactMap { $0.files.count > 1 ? $0.files[1] : $0.files.first }
                } else {
                    return communityItems.compactMap { $0.files.count > 1 ? $0.files[1] : $0.files.first }
                }
            }
        
        visibleItems
            .drive(filterCollectionView.rx.items(
                cellIdentifier: TodayAuthorImageCollectionViewCell.identifier,
                cellType: TodayAuthorImageCollectionViewCell.self
            )) { _, element, cell in
                cell.configure(urlString: element)
            }
            .disposed(by: disposeBag)
        
        Driver
            .combineLatest(output.userFilterItems, output.userCommunityItems, output.selectedSegment)
            .drive(onNext: { [weak self] (filterItems, communityItems, selected) in
                guard let self else { return }
                let isFilterTab = selected == 0
                let currentItemsCount = isFilterTab ? filterItems.count : communityItems.count
                self.emptyBackgroundLabel.text = isFilterTab
                    ? "사용자가 만든 필터가 존재하지 않습니다."
                    : "사용자가 작성한 게시글이 존재하지 않습니다."
                self.filterCollectionView.backgroundView =
                    currentItemsCount == 0 ? self.emptyBackgroundLabel : nil
                self.filterCollectionView.isHidden = false
                if currentItemsCount == 0 {
                    let minHeight = self.minimumFilterHeight()
                    self.filterCollectionHeightConstraint?.update(offset: minHeight)
                    self.filterCollectionView.layoutIfNeeded()
                    self.filterCollectionView.backgroundView?.frame = self.filterCollectionView.bounds
                }
            })
            .disposed(by: disposeBag)

        filterCollectionView.rx
            .observe(CGSize.self, "contentSize")
            .compactMap { $0?.height }
            .distinctUntilChanged()
            .subscribe(with: self) { owner, height in
                let minHeight = owner.minimumFilterHeight()
                owner.filterCollectionHeightConstraint?.update(offset: max(height, minHeight))
            }
            .disposed(by: disposeBag)

        hashTagCollectionView.rx.setDelegate(self)
            .disposed(by: disposeBag)
    }
    

    private func minimumFilterHeight() -> CGFloat {
        let segmentFrame = segmentContainerView.convert(segmentContainerView.bounds, to: scrollView)
        let available = scrollView.bounds.height
            - segmentFrame.maxY
            - 20
            - scrollView.adjustedContentInset.bottom
        return max(available, 0)
    }

    private func updateSegmentSelection(selectedIndex: Int, animated: Bool) {
        let selectedText = GrayStyle.gray30.color
        let normalText = GrayStyle.gray75.color

        let buttons = [leftSegmentButton, rightSegmentButton]
        for (index, button) in buttons.enumerated() {
            let isSelected = index == selectedIndex
            button.setTitleColor(isSelected ? selectedText : normalText, for: .normal)
        }

        let containerWidth = segmentContainerView.bounds.width
        guard containerWidth > 0 else { return }
        let indicatorX = (containerWidth / 2) * CGFloat(selectedIndex)
        segmentIndicatorLeadingConstraint?.update(offset: indicatorX)

        if animated {
            UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseOut]) {
                self.segmentContainerView.layoutIfNeeded()
            }
        } else {
            segmentContainerView.layoutIfNeeded()
        }
    }
}

extension UserProfileViewController: UICollectionViewDelegateFlowLayout {
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
        let spacing: CGFloat = 8
        let totalSpacing = spacing * 2
        let width = (collectionView.bounds.width - totalSpacing) / 3
        return CGSize(width: width, height: width)
    }
}
