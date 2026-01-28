//
//  FeedListTableViewCell.swift
//  Filo
//
//  Created by 이상민 on 01/23/26.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class FeedListTableViewCell: BaseTableViewCell {
    private(set) var disposeBag = DisposeBag()
    
    var likeTapped: ControlEvent<Void> {
        likeButton.rx.tap
    }
    private let thumbnailImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let likeButton = LikeButton()
    
    private let textView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 8
        return view
    }()
    
    private let titleAndCategorykView: UIView = {
        let view = UIView()
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .Mulggeol.body1
        label.textColor = GrayStyle.gray30.color
        label.numberOfLines = 1
        label.lineBreakMode = .byClipping
        return label
    }()
    
    private let categoryLabelbox: UIView = {
        let view = UIView()
        view.backgroundColor = Brand.blackTurquoise.color
        view.clipsToBounds = true
        return view
    }()
    
    private let categoryLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.caption1
        label.textColor = GrayStyle.gray60.color
        return label
    }()
    
    private let nicknameLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.body1
        label.textColor = GrayStyle.gray75.color
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.caption1
        label.textColor = GrayStyle.gray60.color
        label.numberOfLines = 2
        return label
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag = DisposeBag()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        categoryLabelbox.layoutIfNeeded()
        categoryLabelbox.layer.cornerRadius = categoryLabelbox.bounds.height / 2
    }
    
    override func configureHierarchy() {
        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(likeButton)
        contentView.addSubview(textView)
        
        textView.addArrangedSubview(titleAndCategorykView)
        titleAndCategorykView.addSubview(titleLabel)
        titleAndCategorykView.addSubview(categoryLabelbox)
        categoryLabelbox.addSubview(categoryLabel)
        textView.addArrangedSubview(nicknameLabel)
        textView.addArrangedSubview(descriptionLabel)
    }
    
    override func configureLayout() {
        thumbnailImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.verticalEdges.equalToSuperview().inset(20)
            make.height.equalTo(120)
            make.width.equalTo(100)
        }
        
        likeButton.snp.makeConstraints { make in
            make.bottom.trailing.equalTo(thumbnailImageView).inset(4)
        }
        
        textView.snp.makeConstraints { make in
            make.leading.equalTo(thumbnailImageView.snp.trailing).offset(20)
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview().offset(20)
            make.bottom.lessThanOrEqualToSuperview().inset(-20)
        }
        
        titleAndCategorykView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.horizontalEdges.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.verticalEdges.leading.equalToSuperview()
        }
        
        categoryLabelbox.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.trailing).offset(8)
            make.verticalEdges.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
        }
        
        categoryLabel.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview().inset(6)
            make.horizontalEdges.equalToSuperview().inset(12)
        }
    }
    
    override func configureView() {
        selectionStyle = .none
    }
    
    func configure(_ item: FilterSummaryResponseEntity, isLiked: Bool) {
        thumbnailImageView.setKFImage(urlString: item.files[1])
        setLiked(isLiked)
        titleLabel.text = item.title
        if let category = item.category{
            categoryLabel.text = "#\(category)"
        }
        nicknameLabel.text = item.creator.nick
        descriptionLabel.text = item.description

        Observable
            .combineLatest(LikeStore.shared.likedIds, LikeStore.shared.likeCounts)
            .compactMap { likedIds, counts -> Bool? in
                guard counts[item.filterId] != nil else { return nil }
                return likedIds.contains(item.filterId)
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] liked in
                self?.setLiked(liked)
            })
            .disposed(by: disposeBag)
    }

    func setLiked(_ isLiked: Bool) {
        likeButton.isSelected = isLiked
    }
}
