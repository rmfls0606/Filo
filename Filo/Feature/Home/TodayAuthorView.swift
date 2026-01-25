//
//  TodayAuthorView.swift
//  Filo
//
//  Created by 이상민 on 1/22/26.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class TodayAuthorView: BaseView {
    //MARK: - Properties
    private let disposeBag = DisposeBag()
    
    //MARK: - UI
    private let todayAuthorTitle: UILabel = {
        let label = UILabel()
        label.text = "오늘의 작가 소개"
        label.textColor = GrayStyle.gray60.color
        label.font = .Pretendard.body1
        return label
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

    private lazy var authorImageCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 16
        let spacing = 16.0
        let padding = 20.0
        let width = (UIScreen.main.bounds.width - padding - (2 * spacing)) / 2.8
        let height = width * 0.6
        layout.itemSize = CGSize(width: width, height: height)
        
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.register(TodayAuthorImageCollectionViewCell.self, forCellWithReuseIdentifier: TodayAuthorImageCollectionViewCell.identifier)
        view.showsHorizontalScrollIndicator = false
        view.contentInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        return view
    }()
    
    private lazy var hashtagCollectionView: UICollectionView = {
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
    
    private let authorIntroductionLabel: UILabel = {
        let label = UILabel()
        label.font = .Mulggeol.caption1
        label.textColor = GrayStyle.gray60.color
        return label
    }()
    
    private let authorDescriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.caption1
        label.textColor = GrayStyle.gray60.color
        label.numberOfLines = 0
        return label
    }()
    
    private var authorImageCollectionHeight: CGFloat {
        guard let height = (authorImageCollectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize.height else {
            return 0
        }
        return height
    }
    
    private var hashtagCollectionHeight: CGFloat {
        guard let font = UIFont.Pretendard.caption1 else {
            return 0
        }
        return font.lineHeight + 8
    }
    
    override func configureHierarchy() {
        addSubview(todayAuthorTitle)
        addSubview(authorIntroductionStackView)
        
        authorIntroductionStackView.addArrangedSubview(authorProfileBox)
        authorProfileBox.addSubview(authorProfileImage)
        authorProfileBox.addSubview(authorNameStackView)

        authorNameStackView.addArrangedSubview(authorName)
        authorNameStackView.addArrangedSubview(authorNickname)
        
        authorIntroductionStackView.addArrangedSubview(authorImageCollectionView)
        
        authorIntroductionStackView.addArrangedSubview(hashtagCollectionView)
        
        authorIntroductionStackView.addArrangedSubview(authorIntroductionLabel)
        
        authorIntroductionStackView.addArrangedSubview(authorDescriptionLabel)
    }
    
    override func configureLayout() {
        todayAuthorTitle.snp.makeConstraints { make in
            make.top.horizontalEdges.equalToSuperview().inset(20)
        }
        
        authorIntroductionStackView.snp.makeConstraints { make in
            make.top.equalTo(todayAuthorTitle.snp.bottom).offset(20)
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        authorProfileBox.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(4)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(72)
        }
        
        authorProfileImage.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
            make.size.equalTo(72)
        }
        
        authorNameStackView.snp.makeConstraints { make in
            make.leading.equalTo(authorProfileImage.snp.trailing).offset(20)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview()
        }
        
        authorImageCollectionView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(authorImageCollectionHeight)
        }
        
        hashtagCollectionView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(hashtagCollectionHeight)
        }
        
        authorIntroductionLabel.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        
        authorDescriptionLabel.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(20)
            make.bottom.equalToSuperview()
        }
    }
    
    func bind(items: Driver<TodayAuthorResponseEntity>){
        items
            .map{ $0.author }
            .drive(with: self){ owner, author in
                owner.authorProfileImage.setKFImage(urlString: author.profileImage)
                owner.authorName.text = author.name
                owner.authorNickname.text = author.nick
                owner.authorIntroductionLabel.text = author.introduction
                owner.authorDescriptionLabel.text = author.description
            }
            .disposed(by: disposeBag)
        
        items
            .map { $0.filters }
            .drive(authorImageCollectionView.rx.items(
                cellIdentifier: TodayAuthorImageCollectionViewCell.identifier,
                cellType: TodayAuthorImageCollectionViewCell.self
            )){ _, element, cell in
                cell.configure(urlString: element.files[1])
            }
            .disposed(by: disposeBag)

        items
            .map { $0.author.hashTags }
            .drive(hashtagCollectionView.rx.items(
                cellIdentifier: TodayAuthorHashtagCollectionViewCell.identifier,
                cellType: TodayAuthorHashtagCollectionViewCell.self
            )) { _, element, cell in
                cell.configure(element)
            }
            .disposed(by: disposeBag)
    }
}
