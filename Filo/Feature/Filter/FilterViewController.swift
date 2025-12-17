//
//  FilterViewController.swift
//  Filo
//
//  Created by 이상민 on 12/17/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class FilterViewController: BaseViewController {
    //MARK: - Properties
    private let disposeBag = DisposeBag()
    private let viewModel = FilterViewModel()
    private var categoryDataSource: UICollectionViewDiffableDataSource<FilterCategorySection, FilterCategoryEntity>!
    
    //MARK: - UI
    private let filterScrollView: UIScrollView = {
        let view = UIScrollView()
        view.showsVerticalScrollIndicator = false
        return view
    }()
    
    private let filterStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 20
        return view
    }()
    
    //필터명
    private let filterNameTitle = FilterTitleView(title: "필터명")
    private let filterNameTextField: InsetTextField = {
        let field = InsetTextField()
        field.placeholder = "필터 이름을 입력해주세요."
        return field
    }()
    private lazy var filterNameSection = FilterSectionView(titleView: filterNameTitle, contentView: filterNameTextField)
    
    //카테고리
    private let filterCategoryTitle = FilterTitleView(title: "카테고리")
    private lazy var filterCategoryCollectionView: UICollectionView = {
        let layout = makeCategoryLayout()
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.register(
            FilterCategoryCollectionViewCell.self,
            forCellWithReuseIdentifier: FilterCategoryCollectionViewCell.identifier
        )
        view.showsHorizontalScrollIndicator = false
        view.alwaysBounceVertical = false
        view.bounces = false
        return view
    }()
    private lazy var filterCategorySection = FilterSectionView(titleView: filterCategoryTitle, contentView: filterCategoryCollectionView)
    
    //필터 소개
    private let filterIntroduceTitle = FilterTitleView(title: "필터 소개")
    private let filterIntroduceTextField: InsetTextField = {
        let field = InsetTextField()
        field.placeholder = "이 필터에 대해 간단하게 소개해주세요."
        return field
    }()
    private lazy var filterIntroduceSection = FilterSectionView(titleView: filterIntroduceTitle, contentView: filterIntroduceTextField)
    
    //판매 가격
    private let filterPriceTitle = FilterTitleView(title: "판매 가격")
    private let filterPriceTextField: InsetTextField = {
        let field = InsetTextField()
        field.placeholder = "1,000"
        return field
    }()
    private lazy var filterPriceSection = FilterSectionView(titleView: filterPriceTitle, contentView: filterPriceTextField)
    
    override func configureHierarchy() {
        view.addSubview(filterScrollView)
        
        filterScrollView.addSubview(filterStackView)
        
        filterStackView.addArrangedSubview(filterNameSection)
        filterStackView.addArrangedSubview(filterCategorySection)
        filterStackView.addArrangedSubview(filterIntroduceSection)
        filterStackView.addArrangedSubview(filterPriceSection)
    }
    
    override func configureLayout() {
        filterScrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        filterStackView.snp.makeConstraints { make in
            make.horizontalEdges.equalTo(filterScrollView.frameLayoutGuide).inset(20)
            make.verticalEdges.equalTo(filterScrollView.contentLayoutGuide).inset(20)
        }
        
        filterCategoryCollectionView.snp.makeConstraints { make in
            make.height.equalTo(30)
        }
    }
    
    override func configureView() {
        navigationItem.title = "MAKE"
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "save"))
        navigationItem.rightBarButtonItem?.tintColor = GrayStyle.gray75.color
        view.backgroundColor = .black
        configureCategoryDataSource()
    }
    
    override func configureBind() {
        let input = FilterViewModel.Input(
            categorySelected: filterCategoryCollectionView.rx.itemSelected
                .compactMap({ [weak self] indexPath in
                    self?.categoryDataSource
                        .itemIdentifier(for: indexPath)?.type
                })
        )
        
        let output = viewModel.transform(input: input)
        
        output.categories
            .drive { [weak self] items in
                self?.applyCategorySnapshot(items)
            }
            .disposed(by: disposeBag)
    }
}

extension FilterViewController{
    private func makeCategoryLayout() -> UICollectionViewLayout{
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .estimated(50),
            heightDimension: .estimated(30)
        )
        
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .estimated(50),
            heightDimension: .absolute(30)
        )
        
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = 8
        section.contentInsets = .zero
        
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    private func configureCategoryDataSource(){
        categoryDataSource = UICollectionViewDiffableDataSource<FilterCategorySection, FilterCategoryEntity>(collectionView: filterCategoryCollectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: FilterCategoryCollectionViewCell.identifier,
                for: indexPath
            ) as? FilterCategoryCollectionViewCell else {
                return UICollectionViewCell()
            }
            
            cell.configure(itemIdentifier)
            return cell
        })
    }
    
    private func applyCategorySnapshot(_ items: [FilterCategoryEntity]){
        var snapshot = NSDiffableDataSourceSnapshot<FilterCategorySection, FilterCategoryEntity>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items)
        categoryDataSource.apply(snapshot)
    }
}
