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
        return view
    }()
    
    private let todayFilterImageView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = .orange
        return view
    }()
    
    private let filterImageGradientView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = .black.withAlphaComponent(0.3)
        return view
    }()
    
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
        label.text = "새싹을 담은 필터 청록 새록"
        label.font = .Mulggeol.title1
        label.textColor = GrayStyle.gray30.color
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        label.lineBreakStrategy = .hangulWordPriority
        return label
    }()
    
    private let todayFilterDescription: UILabel = {
        let label = UILabel()
        label.text = "햇살 아래 돋아나는 새싹처럼, 맑고 투명한 빝을 담은 자연 감성 필터입니다. 너무 과하지 않게, 부드러운 색감으로 분위기를 사렬줍닏. 새로운 싲ㄱ, 순수한 감정을 담고 싶을 때 이 필터를 사용해보세요."
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
    
    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    override func configureHierarchy() {
        view.addSubview(homeScrollView)
        homeScrollView.addSubview(homeStacView)
        
        homeStacView.addArrangedSubview(todayFilterIntroductionView)
        todayFilterIntroductionView.addSubview(todayFilterImageView)
        todayFilterIntroductionView.addSubview(filterUseButton)
        
        todayFilterIntroductionView.addSubview(todayFilterIntroductionTitleBox)
        todayFilterIntroductionTitleBox.addSubview(todayFilterIntroductionTitle)
        todayFilterIntroductionTitleBox.addSubview(todayFilterTitle)
        
        todayFilterIntroductionView.addSubview(todayFilterDescription)
        
        todayFilterIntroductionView.addSubview(filterCategoryStackView)
    }
    
    override func configureLayout() {
        homeScrollView.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview()
            make.horizontalEdges.equalTo(view.safeAreaLayoutGuide)
        }
        
        homeStacView.snp.makeConstraints { make in
            make.height.equalTo(homeScrollView.contentLayoutGuide)
            make.width.equalTo(homeScrollView.frameLayoutGuide)
        }
        
        todayFilterIntroductionView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.horizontalEdges.equalToSuperview()
        }
        
        todayFilterImageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(todayFilterIntroductionView.snp.height)
        }
        
        filterUseButton.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(20)
        }
        
        todayFilterIntroductionTitleBox.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        
        todayFilterIntroductionTitle.snp.makeConstraints { make in
            make.top.horizontalEdges.equalToSuperview()
        }
        
        todayFilterTitle.snp.makeConstraints { make in
            make.top.equalTo(todayFilterIntroductionTitle.snp.bottom).offset(4)
            make.horizontalEdges.bottom.equalToSuperview()
        }
        
        todayFilterDescription.snp.makeConstraints { make in
            make.top.equalTo(todayFilterIntroductionTitleBox.snp.bottom).offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        
        filterCategoryStackView.snp.makeConstraints { make in
            make.top.equalTo(todayFilterDescription.snp.bottom).offset(40)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.bottom.equalToSuperview()
        }
    }
    
    override func configureView() {
        navigationController?.navigationBar.isHidden = true
    }
    
    override func configureBind() {
        let input = HomeViewModel.Input()
        let output = viewModel.transform(input: input)
        
        output.filterCategories
            .drive(with: self) { owner, categories in
                owner.makeButtons(categories: categories)
            }
            .disposed(by: disposeBag)
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
