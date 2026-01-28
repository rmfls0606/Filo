//
//  FeedViewController.swift
//  Filo
//
//  Created by 이상민 on 12/17/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class FeedViewController: BaseViewController, PinterestLayoutDelegate {
    //MARK: - Properties
    private let viewModel: FeedViewModel
    private let disposeBag = DisposeBag()
    private var orderByButtons: [UIButton] = []
    private var currentFeedItems: [FilterSummaryResponseEntity] = []
    private let likeTappedRelay = PublishRelay<LikeInputTap>()
    
    private var feedBodyHeightConstraint: Constraint?
    
    init(viewModel: FeedViewModel = FeedViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    //MARK: - UI
    private let feedScrollView: UIScrollView = {
        let view = UIScrollView()
        view.showsVerticalScrollIndicator = false
        view.contentInset.bottom = CustomTabBarView.height + 20
        view.verticalScrollIndicatorInsets.bottom = CustomTabBarView.height + 20
        return view
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        return view
    }()
    
    private let topRankingTitleView: UIView = {
        let view = UIView()
        return view
    }()
    
    private let topRankingTitle: UILabel = {
        let label = UILabel()
        label.text = "Top Ranking"
        label.font = .Pretendard.body1
        label.textColor = GrayStyle.gray60.color
        return label
    }()
    
    private let orderByStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.spacing = 10
        return view
    }()
    
    private lazy var rankingCollectionView: UICollectionView = {
        let layout = RankingCarouselLayout()
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.register(RankingCollectionViewCell.self, forCellWithReuseIdentifier: RankingCollectionViewCell.identifier)
        view.showsHorizontalScrollIndicator = false
        view.decelerationRate = .fast
        view.backgroundColor = .clear
        return view
    }()
    
    private let filterFeedTitleView: UIView = {
        let view = UIView()
        return view
    }()
    
    private let filterFeedText: UILabel = {
        let label = UILabel()
        label.text = "Filter Feed"
        label.font = .Pretendard.body1
        label.textColor = GrayStyle.gray60.color
        return label
    }()
    
    private let filterFeedModeText: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = "List Mode"
        config.baseForegroundColor = GrayStyle.gray75.color
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer({ text in
            var outputText = text
            outputText.font = .Pretendard.body1
            return outputText
        })
        let button = UIButton(configuration: config)
        return button
    }()
    
    private let feedBodyView: UIView = {
        let view = UIView()
        return view
    }()

    private let listTableView: UITableView = {
        let view = UITableView()
        view.register(FeedListTableViewCell.self, forCellReuseIdentifier: FeedListTableViewCell.identifier)
        view.separatorStyle = .none
        view.rowHeight = UITableView.automaticDimension
        view.isScrollEnabled = false
        return view
    }()

    private lazy var blockCollectionView: UICollectionView = {
        let layout = PinterestLayout()
        layout.numberOfColumns = 2
        layout.cellPadding = 6
        layout.delegate = self
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.register(FeedBlockCollectionViewCell.self, forCellWithReuseIdentifier: FeedBlockCollectionViewCell.identifier)
        view.isScrollEnabled = false
        view.backgroundColor = .clear
        view.isHidden = true
        return view
    }()
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !blockCollectionView.isHidden {
            updateBlockLayout()
        }
    }
    
    override func configureHierarchy() {
        view.addSubview(feedScrollView)
        
        feedScrollView.addSubview(contentView)
        
        contentView.addSubview(topRankingTitleView)
        topRankingTitleView.addSubview(topRankingTitle)
        
        contentView.addSubview(orderByStackView)
        
        contentView.addSubview(rankingCollectionView)
        
        contentView.addSubview(filterFeedTitleView)
        filterFeedTitleView.addSubview(filterFeedText)
        filterFeedTitleView.addSubview(filterFeedModeText)
        
        contentView.addSubview(feedBodyView)
        feedBodyView.addSubview(listTableView)
        feedBodyView.addSubview(blockCollectionView)
    }
    
    override func configureLayout() {
        feedScrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(feedScrollView.contentLayoutGuide)
            make.width.equalTo(feedScrollView.frameLayoutGuide)
        }
        
        topRankingTitleView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.horizontalEdges.equalToSuperview()
        }
        
        topRankingTitle.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(20)
        }
        
        orderByStackView.snp.makeConstraints { make in
            make.top.equalTo(topRankingTitleView.snp.bottom)
            make.trailing.equalToSuperview().inset(20)
            make.leading.greaterThanOrEqualToSuperview().inset(20)
        }
        
        if let layout = rankingCollectionView.collectionViewLayout as? RankingCarouselLayout {
            rankingCollectionView.snp.makeConstraints { make in
                make.top.equalTo(orderByStackView.snp.bottom).offset(20)
                make.horizontalEdges.equalToSuperview()
                make.height.equalTo(layout.requiredHeight)
            }
        }
        
        filterFeedTitleView.snp.makeConstraints { make in
            make.top.equalTo(rankingCollectionView.snp.bottom).offset(16)
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        
        filterFeedText.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview().inset(20)
            make.leading.equalToSuperview()
        }
        
        filterFeedModeText.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview().inset(20)
            make.trailing.equalToSuperview()
        }
        
        feedBodyView.snp.makeConstraints { make in
            make.top.equalTo(filterFeedTitleView.snp.bottom)
            make.horizontalEdges.equalToSuperview().inset(20)
            feedBodyHeightConstraint = make.height.equalTo(0).constraint
            make.bottom.equalToSuperview()
        }
        
        listTableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        blockCollectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    override func configureView() {
        navigationItem.title = "FEED"
        makeOrderByButtons(OrderByItem.allCases)
    }
    
    override func configureBind() {
        let orderByItemSelected = Observable.merge(
            orderByButtons.enumerated().map{ index, button in
                button.rx.tap.map{ OrderByItem.allCases[index] }
            }
        )
        
        let selectedCell = Observable.merge(
            rankingCollectionView.rx
                .modelSelected((item: FilterSummaryResponseEntity, rank: Int).self)
                .map{$0.item}
                .asObservable(),
            listTableView.rx.modelSelected(FilterSummaryResponseEntity.self).asObservable(),
            blockCollectionView.rx.modelSelected(FilterSummaryResponseEntity.self).asObservable()
        )
        .share(replay: 1)
        
        let input = FeedViewModel.Input(
            orderByItemSelected: orderByItemSelected,
            feedCellTapped: selectedCell,
            feedFilterModeSelected: filterFeedModeText.rx.tap,
            likeTapped: likeTappedRelay.asObservable()
        )
        
        let output = viewModel.transform(input: input)
      
        output.selectedOrder
            .drive(with: self) { owner, selected in
                for (button, type) in zip(owner.orderByButtons, OrderByItem.allCases){
                    button.isSelected = (type == selected)
                }
            }
            .disposed(by: disposeBag)
        
        let rankingItems = output.filtersData
            .map { $0.data.prefix(3) }
            .map { items -> [(item: FilterSummaryResponseEntity, rank: Int)] in
                guard items.count >= 3 else {
                    return items.enumerated().map { ($0.element, $0.offset + 1) }
                }
                return [
                    (items[1], 2),
                    (items[0], 1),
                    (items[2], 3)
                ]
            }
        
        rankingItems
            .drive(rankingCollectionView.rx.items(
                cellIdentifier: RankingCollectionViewCell.identifier,
                cellType: RankingCollectionViewCell.self
            )) { _, data, cell in
                cell.configure(rank: data.rank, data.item)
            }
            .disposed(by: disposeBag)
        
        rankingItems
            .drive(with: self) { owner, items in
                guard !items.isEmpty else { return }
                let indexPath = IndexPath(item: min(1, items.count - 1), section: 0)
                owner.rankingCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
            }
            .disposed(by: disposeBag)
        
        let feedItems = output.filtersData
            .map { Array($0.data.dropFirst(3)) }

        feedItems
            .drive(listTableView.rx.items(
                cellIdentifier: FeedListTableViewCell.identifier,
                cellType: FeedListTableViewCell.self
            )) { [weak self] index, item, cell in
                guard let self else { return }
                cell.configure(item, isLiked: LikeStore.shared.isLiked(id: item.filterId))
                cell.likeTapped
                    .bind(onNext: { [weak self] in
                        guard let self else { return }
                        self.likeTappedRelay.accept(LikeInputTap(
                            item: item
                        ))
                    })
                    .disposed(by: cell.disposeBag)
            }
            .disposed(by: disposeBag)

        output.likeUIUpdate
            .drive(with: self) { owner, update in
                owner.applyLikeUpdate(update)
            }
            .disposed(by: disposeBag)

        output.selectedFilterId
            .drive(with: self) { owner, filterId in
                let vm = DetailViewModel(filterId: filterId)
                let vc = DetailViewController(viewModel: vm)
                owner.navigationController?.pushViewController(vc, animated: true)
            }
            .disposed(by: disposeBag)

        feedItems
            .drive(blockCollectionView.rx.items(
                cellIdentifier: FeedBlockCollectionViewCell.identifier,
                cellType: FeedBlockCollectionViewCell.self
            )) { [weak self] index, item, cell in
                guard let self else { return }
                let ratio = self.aspectRatio(for: item)
                cell.configure(item, imageRatio: ratio)
                let liked = LikeStore.shared.isLiked(id: item.filterId)
                let count = LikeStore.shared.likeCount(id: item.filterId) ?? item.likeCount
                cell.setLiked(liked, count)
                cell.likeTapped
                    .bind { [weak self] in
                        guard let self else { return }
                        self.likeTappedRelay.accept(
                            LikeInputTap(
                            item: item
                            )
                        )
                    }
                    .disposed(by: cell.disposeBag)
            }
            .disposed(by: disposeBag)

        let modeStream = output.feedFilterMode
            .distinctUntilChanged()
            .asObservable()
        
        modeStream
            .map{ $0 ? "List Mode" : "Block Mode"}
            .bind(to: filterFeedModeText.rx.title())
            .disposed(by: disposeBag)

        Observable
            .combineLatest(modeStream, feedItems.asObservable())
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isList, items in
                guard let self else { return }
                self.currentFeedItems = items
                self.listTableView.isHidden = !isList
                self.blockCollectionView.isHidden = isList
                if isList {
                    self.listTableView.layoutIfNeeded()
                    self.feedBodyHeightConstraint?.update(offset: self.listTableView.contentSize.height)
                } else {
                    self.updateBlockLayout()
                }
            })
            .disposed(by: disposeBag)

        let listHeight = listTableView.rx
            .observe(CGSize.self, "contentSize")
            .compactMap { $0?.height }
            .distinctUntilChanged()

        let blockHeight = blockCollectionView.rx
            .observe(CGSize.self, "contentSize")
            .compactMap { $0?.height }
            .distinctUntilChanged()

        Observable
            .combineLatest(modeStream, listHeight, blockHeight)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isList, listH, blockH in
                guard let self else { return }
                self.feedBodyHeightConstraint?.update(offset: isList ? listH : blockH)
            })
            .disposed(by: disposeBag)
    }

    private func updateBlockLayout() {
        let layout = blockCollectionView.collectionViewLayout as? PinterestLayout
        layout?.invalidateLayout()
        blockCollectionView.collectionViewLayout.invalidateLayout()
        blockCollectionView.layoutIfNeeded()
        feedBodyHeightConstraint?.update(offset: blockCollectionView.collectionViewLayout.collectionViewContentSize.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, heightForItemAt indexPath: IndexPath, with width: CGFloat) -> CGFloat {
        guard indexPath.item < currentFeedItems.count else { return width }
        let item = currentFeedItems[indexPath.item]
        let imageHeight = width * aspectRatio(for: item)
        let textWidth = width - 16
        let nicknameHeight = boundingHeight(item.creator.nick, font: .Pretendard.caption1 ?? UIFont.systemFont(ofSize: 12), width: textWidth)
        let topSpacing: CGFloat = 8
        let bottomInset: CGFloat = 0
        return imageHeight + topSpacing + nicknameHeight + bottomInset
    }
    
    private func aspectRatio(for item: FilterSummaryResponseEntity) -> CGFloat {
        let seed = item.filterId
        let hash = stableHash(seed)
        let minRatio: CGFloat = 0.8
        let maxRatio: CGFloat = 1.8
        let unit = CGFloat(abs(hash % 1000)) / 1000.0
        return minRatio + (maxRatio - minRatio) * unit
    }
    
    private func stableHash(_ string: String) -> Int {
        var hash = 5381
        for scalar in string.unicodeScalars {
            hash = ((hash << 5) &+ hash) &+ Int(scalar.value)
        }
        return hash
    }

    private func applyLikeUpdate(_ update: OutputLikeUpdate) {
        if let index = currentFeedItems.firstIndex(where: { $0.filterId == update.filterId }) {
            let indexPathRow = IndexPath(row: index, section: 0)
            if let cell = listTableView.cellForRow(at: indexPathRow) as? FeedListTableViewCell {
                cell.setLiked(update.liked)
            }
            
            let indexPathItem = IndexPath(item: index, section: 0)
            if let cell = blockCollectionView.cellForItem(at: indexPathItem) as? FeedBlockCollectionViewCell{
                cell.setLiked(update.liked, update.likeCount)
            }
        }
    }

    private func boundingHeight(_ text: String, font: UIFont, width: CGFloat) -> CGFloat {
        let rect = (text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        return ceil(rect.height)
    }

    private func makeOrderByButtons(_ items: [OrderByItem]) {
        orderByButtons = items.enumerated().map { index, item in
            var config = UIButton.Configuration.filled()
            config.cornerStyle = .capsule
            config.baseForegroundColor = GrayStyle.gray75.color
            config.baseBackgroundColor = Brand.blackTurquoise.color
            config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
            config.attributedTitle = AttributedString(item.rawValue, attributes: AttributeContainer([
                .font: UIFont.Pretendard.body2 ?? UIFont.systemFont(ofSize: 14)
            ]))
            
            let button = UIButton(configuration: config)
            button.configurationUpdateHandler = { button in
                var config = button.configuration
                if button.isSelected{
                    config?.baseForegroundColor = GrayStyle.gray45.color
                    config?.baseBackgroundColor = Brand.brightTurquoise.color
                }else{
                    config?.baseForegroundColor = GrayStyle.gray75.color
                    config?.baseBackgroundColor = Brand.blackTurquoise.color
                }

                button.configuration = config
            }
            button.tag = index
            return button
        }
        orderByButtons.forEach { orderByStackView.addArrangedSubview($0) }
    }
}
