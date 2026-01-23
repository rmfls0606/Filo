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

final class FeedViewController: BaseViewController {
    //MARK: - Properties
    private let viewModel: FeedViewModel
    private let disposeBag = DisposeBag()
    private var orderByButtons: [UIButton] = []
    
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
    
    private var feedBodyHeightConstraint: Constraint?
    
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
    }
    
    override func configureLayout() {
        feedScrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        contentView.snp.makeConstraints { make in
            make.height.equalTo(feedScrollView.contentLayoutGuide)
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
        
        let input = FeedViewModel.Input(
            orderByItemSelected: orderByItemSelected,
            feedFilterModeSelected: filterFeedModeText.rx.tap
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
            .map { items -> [(item: FilterSummaryResponseDTO, rank: Int)] in
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
            .map { $0.data.dropFirst(3)}

        feedItems
            .drive(listTableView.rx.items(
                cellIdentifier: FeedListTableViewCell.identifier,
                cellType: FeedListTableViewCell.self
            )) { _, item, cell in
                cell.configure(item)
            }
            .disposed(by: disposeBag)

        feedItems
            .drive(with: self) { owner, items in
                owner.listTableView.layoutIfNeeded()
                owner.feedBodyHeightConstraint?.update(offset: owner.listTableView.contentSize.height)
            }
            .disposed(by: disposeBag)

        listTableView.rx
            .observe(CGSize.self, "contentSize")
            .compactMap { $0?.height }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] height in
                guard let self else { return }
                self.feedBodyHeightConstraint?.update(offset: height)
            })
            .disposed(by: disposeBag)
        
        output.feedFilterMode
            .map{ $0 ? "List Mode" : "Block Mode" }
            .drive(filterFeedModeText.rx.title())
            .disposed(by: disposeBag)
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
