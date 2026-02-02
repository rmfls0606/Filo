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
//        label.text = "윤새싹"
        label.font = .Mulggeol.body1
        label.textColor = GrayStyle.gray30.color
        return label
    }()
    
    private let userNickname: UILabel = {
        let label = UILabel()
//        label.text = "SESAC YOON"
        label.font = .Pretendard.body1
        label.textColor = GrayStyle.gray75.color
        return label
    }()
    
    private let hashTagCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 4
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.register(TodayAuthorHashtagCollectionViewCell.self, forCellWithReuseIdentifier: TodayAuthorHashtagCollectionViewCell.identifier)
        return view
    }()
    
    //MARK: - Properties
    private let viewModel: UserProfileViewModel
    private let disposeBag = DisposeBag()
    
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
        
        userIntroductionStackView.addArrangedSubview(hashTagCollectionView)
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
            make.trailing.lessThanOrEqualToSuperview()
        }
        
        hashTagCollectionView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(24)
        }
    }
    
    override func configureView() {
        navigationItem.title = "PROFILE"
    }
    
    override func configureBind() {
        let input = UserProfileViewModel.Input()
        
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

        output.profileItem
            .compactMap{ $0?.hashTags }
            .drive(hashTagCollectionView.rx.items(cellIdentifier: TodayAuthorHashtagCollectionViewCell.identifier, cellType: TodayAuthorHashtagCollectionViewCell.self)){ index, element, cell in
                cell.configure(element)
            }
            .disposed(by: disposeBag)
    }
}
