//
//  HomeViewController.swift
//  Filo
//
//  Created by 이상민 on 12/17/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class HomeViewController: BaseViewController {
    
    //MARK: - Properties
    private let viewModel: HomeViewModel
    private let disposeBag = DisposeBag()
    private var filterPropButtons = [UIButton]()
    
    //MARK: - UI
    private let homeScrollView: UIScrollView = {
        let view = UIScrollView()
        view.showsVerticalScrollIndicator = false
        view.contentInsetAdjustmentBehavior = .never
        return view
    }()
    
    private let homeStacView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 20
        return view
    }()
    
    private let todayFilterIntroductionView: UIView = {
        let view = UIView()
        view.backgroundColor = .orange
        return view
    }()
    
    private let todayFilterImageView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = GrayStyle.gray60.color
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()
    
    private let gradientView = DarkGradientView()
    
    private let filterUseButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.attributedTitle = AttributedString("사용해보기", attributes: AttributeContainer([.font: UIFont.Pretendard.caption1 ?? .systemFont(ofSize: 12)]))
        config.baseForegroundColor = GrayStyle.gray60.color
        config.baseBackgroundColor = GrayStyle.gray75.color?.withAlphaComponent(0.5)
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8)
        config.background.cornerRadius = 8
        config.background.strokeWidth = 1.0
        config.background.strokeColor = GrayStyle.gray75.color?.withAlphaComponent(0.5)
        
        let button = UIButton(configuration: config)
        return button
    }()
    
    private let todayFilterIntroductionTitleBox: UIView = {
        let view = UIView()
        return view
    }()
    
    private let todayFilterIntroductionTitle: UILabel = {
        let label = UILabel()
        label.text = "오늘의 필터 소개"
        label.font = .Pretendard.body3
        label.textColor = GrayStyle.gray60.color
        return label
    }()
    
    private let todayFilterTitle: UILabel = {
        let label = UILabel()
        label.font = .Mulggeol.title1
        label.textColor = GrayStyle.gray30.color
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        label.lineBreakStrategy = .hangulWordPriority
        return label
    }()
    
    private let todayFilterDescription: UILabel = {
        let label = UILabel()
        label.text = "..."
        label.font = .Pretendard.caption1
        label.textColor = GrayStyle.gray60.color
        label.numberOfLines = 4
        label.lineBreakMode = .byTruncatingTail
        label.lineBreakStrategy = .hangulWordPriority
        return label
    }()
    
    private let filterCategoryStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.spacing = 20
        view.distribution = .fillEqually
        return view
    }()
    
    //핫 트렌드
    private let hotTrendView = HotTrendView()
    
    //오늘의 작가 소개
    private let todayAuthorView = TodayAuthorView()
    
    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let bottomInset = CustomTabBarView.height + view.safeAreaInsets.bottom
        homeScrollView.contentInset.bottom = bottomInset + 20
        homeScrollView.verticalScrollIndicatorInsets.bottom = bottomInset + 20
    }
    
    override func configureHierarchy() {
        view.addSubview(homeScrollView)
        homeScrollView.addSubview(homeStacView)
        
        homeStacView.addArrangedSubview(todayFilterIntroductionView)
        todayFilterIntroductionView.addSubview(todayFilterImageView)
        todayFilterIntroductionView.addSubview(filterUseButton)
        
        todayFilterIntroductionView.addSubview(gradientView)
        
        todayFilterIntroductionView.addSubview(todayFilterIntroductionTitleBox)
        todayFilterIntroductionTitleBox.addSubview(todayFilterIntroductionTitle)
        todayFilterIntroductionTitleBox.addSubview(todayFilterTitle)
        
        todayFilterIntroductionView.addSubview(todayFilterDescription)
        
        todayFilterIntroductionView.addSubview(filterCategoryStackView)
        
        homeStacView.addArrangedSubview(hotTrendView)
        
        homeStacView.addArrangedSubview(todayAuthorView)
    }
    
    override func configureLayout() {
        homeScrollView.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview()
            make.horizontalEdges.equalTo(view.safeAreaLayoutGuide)
        }
        
        homeStacView.snp.makeConstraints { make in
            make.edges.equalTo(homeScrollView.contentLayoutGuide)
            make.width.equalTo(homeScrollView.frameLayoutGuide)
        }
        
        todayFilterIntroductionView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(UIScreen.main.bounds.height * 0.64)
        }
        
        todayFilterImageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        gradientView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        filterUseButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).inset(12)
            make.trailing.equalToSuperview().inset(20)
        }
        
        todayFilterIntroductionTitleBox.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(20)
            make.bottom.equalTo(todayFilterIntroductionTitle.snp.top).offset(-20)
        }
        
        todayFilterIntroductionTitle.snp.makeConstraints { make in
            make.top.horizontalEdges.equalToSuperview()
            make.bottom.equalTo(todayFilterTitle.snp.top).offset(-4)
        }
        
        todayFilterTitle.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalTo(todayFilterDescription.snp.top).offset(-20)
        }
        
        todayFilterDescription.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(20)
            make.bottom.equalTo(filterCategoryStackView.snp.top).offset(-40)
        }
        
        filterCategoryStackView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(24)
        }
        
        //핫 트렌드
        hotTrendView.snp.makeConstraints { make in
            make.height.equalTo(hotTrendView.calculatedHeight)
        }
    }
    
    override func configureView() {
        navigationController?.navigationBar.isHidden = true
        
        gradientView.frame = todayFilterImageView.bounds
        gradientView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    override func configureBind() {
        let input = HomeViewModel.Input()
        let output = viewModel.transform(input: input)
        
        output.filterCategories
            .drive(with: self) { owner, categories in
                owner.makeButtons(categories: categories)
            }
            .disposed(by: disposeBag)
        
        output.todayFilterData
            .drive(with: self){ owner, data in
                owner.todayFilterImageView.setKFImage(urlString: data.files[1])
                owner.todayFilterTitle.text = data.title
                owner.todayFilterDescription.text = data.description
            }
            .disposed(by: disposeBag)

        hotTrendView.bind(items: output.hotTrendItems)
        
        todayAuthorView.bind(items: output.todayAuthorData)
    }
    
    //MARK: - function
    private func makeButtons(categories: [FilterCategoryType]){
        for category in categories{
            filterCategoryStackView.addArrangedSubview(applyButtonConfiguration(category: category))
        }
    }
    
    private func applyButtonConfiguration(category: FilterCategoryType) -> UIButton{
        var config = UIButton.Configuration.filled()
        config.attributedTitle = AttributedString(category.rawValue, attributes: AttributeContainer([
            .font: UIFont.Pretendard.caption2 ?? UIFont.systemFont(ofSize: 10)
        ]))
        config.image = UIImage(named: category.imageName)?.withTintColor(GrayStyle.gray60.color ?? .gray60)
        config.imagePlacement = .top
        config.imagePadding = 2
        
        config.titlePadding = 2
        config.baseForegroundColor = GrayStyle.gray60.color
        config.baseBackgroundColor = GrayStyle.gray75.color?.withAlphaComponent(0.5)
        config.background.cornerRadius = 12
        config.background.strokeWidth = 1
        config.background.strokeColor = GrayStyle.gray75.color?.withAlphaComponent(0.5)
        let button = UIButton(configuration: config)
        return button
    }
}
