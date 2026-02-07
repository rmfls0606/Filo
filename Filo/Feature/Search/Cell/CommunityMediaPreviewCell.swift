//
//  CommunityMediaPreviewCell.swift
//  Filo
//
//  Created by 이상민 on 2/7/26.
//

import UIKit
import SnapKit

final class CommunityMediaPreviewCell: BaseCollectionViewCell {    
    private let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.backgroundColor = GrayStyle.gray90.color
        view.layer.cornerRadius = 8
        return view
    }()
    
    private let playIconView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(systemName: "play.circle.fill")
        view.tintColor = GrayStyle.gray90.color
        view.isHidden = true
        return view
    }()
    
    private let warningIconView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(systemName: "exclamationmark.triangle.fill")
        view.tintColor = UIColor.systemYellow
        view.isHidden = true
        return view
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = GrayStyle.gray75.color
        button.backgroundColor = .clear
        return button
    }()
    
    var onDelete: (() -> Void)?
    
    override func configureHierarchy() {
        contentView.addSubview(imageView)
        contentView.addSubview(playIconView)
        contentView.addSubview(warningIconView)
        contentView.addSubview(closeButton)
    }
    
    override func configureLayout() {
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        playIconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(28)
        }
        
        warningIconView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(6)
            make.bottom.equalToSuperview().inset(6)
            make.size.equalTo(18)
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(4)
            make.trailing.equalToSuperview().inset(4)
            make.size.equalTo(20)
        }
    }
    
    override func configureView() {
        contentView.backgroundColor = .clear
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        playIconView.isHidden = true
        warningIconView.isHidden = true
        onDelete = nil
    }
    
    func configure(item: PostMediaItem) {
        imageView.image = item.thumbnail
        playIconView.isHidden = !item.isVideo
        warningIconView.isHidden = item.isValid
    }
    
    @objc private func closeTapped() {
        onDelete?()
    }
}
