//
//  SearchUserTableViewCell.swift
//  Filo
//
//  Created by 이상민 on 2/7/26.
//

import UIKit
import SnapKit

final class SearchUserTableViewCell: BaseTableViewCell {
    private let profileImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.backgroundColor = GrayStyle.gray90.color
        view.image = UIImage(systemName: "person")
        view.tintColor = GrayStyle.gray60.color
        view.layer.cornerRadius = 20
        return view
    }()

    private let iconImageView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(systemName: "magnifyingglass")
        view.tintColor = GrayStyle.gray60.color
        view.contentMode = .center
        view.isHidden = true
        return view
    }()
    
    private let nickLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.body1
        label.textColor = GrayStyle.gray30.color
        label.numberOfLines = 1
        return label
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.caption1
        label.textColor = GrayStyle.gray60.color
        label.numberOfLines = 1
        return label
    }()
    
    private let textStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        return stack
    }()
    
    override func configureHierarchy() {
        contentView.addSubview(profileImageView)
        contentView.addSubview(iconImageView)
        contentView.addSubview(textStack)
        textStack.addArrangedSubview(nickLabel)
        textStack.addArrangedSubview(nameLabel)
    }
    
    override func configureLayout() {
        profileImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(40)
        }

        iconImageView.snp.makeConstraints { make in
            make.center.equalTo(profileImageView)
            make.size.equalTo(18)
        }
        
        textStack.snp.makeConstraints { make in
            make.leading.equalTo(profileImageView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().inset(16)
            make.verticalEdges.equalToSuperview().inset(10)
        }
    }
    
    override func configureView() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        profileImageView.image = nil
        iconImageView.isHidden = true
        nameLabel.isHidden = false
        nickLabel.font = .Pretendard.body1
        profileImageView.layer.cornerRadius = 20
        profileImageView.backgroundColor = GrayStyle.gray90.color
        profileImageView.contentMode = .scaleAspectFill
    }
    
    func configure(item: UserInfoResponseDTO) {
        iconImageView.isHidden = true
        nameLabel.isHidden = false
        nickLabel.font = .Pretendard.body1
        profileImageView.layer.cornerRadius = 20
        profileImageView.backgroundColor = GrayStyle.gray90.color
        profileImageView.contentMode = .scaleAspectFill
        nickLabel.text = item.nick
        nameLabel.text = item.name ?? item.introduction ?? ""
        
        if let url = item.profileImage {
            profileImageView.setKFImage(urlString: url)
        } else {
            profileImageView.image = nil
        }
    }

    func configureKeyword(text: String) {
        nickLabel.text = text
        nameLabel.text = nil
        nameLabel.isHidden = true
        profileImageView.image = nil
        nickLabel.font = .Pretendard.body2
        profileImageView.layer.cornerRadius = 20
        profileImageView.backgroundColor = GrayStyle.gray90.color
        profileImageView.contentMode = .center
        iconImageView.isHidden = false
    }
}
