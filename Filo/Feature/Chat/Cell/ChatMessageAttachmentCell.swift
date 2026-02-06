//
//  ChatMessageAttachmentCell.swift
//  Filo
//
//  Created by 이상민 on 2/6/26.
//

import UIKit
import SnapKit

final class ChatMessageAttachmentCell: BaseCollectionViewCell {
    private let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.layer.cornerRadius = 10
        view.backgroundColor = GrayStyle.gray75.color?.withAlphaComponent(0.25)
        return view
    }()

    private let fileBadge: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.caption2
        label.textColor = GrayStyle.gray0.color
        label.text = "FILE"
        label.textAlignment = .center
        label.backgroundColor = Brand.deepTurquoise.color
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.isHidden = true
        return label
    }()

    override func configureHierarchy() {
        contentView.addSubview(imageView)
        contentView.addSubview(fileBadge)
    }
    
    override func configureLayout() {
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        fileBadge.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalTo(44)
            make.height.equalTo(22)
        }
    }

    func bind(urlString: String) {
        let isImage = urlString.lowercased().hasSuffix(".jpg") ||
        urlString.lowercased().hasSuffix(".jpeg") ||
        urlString.lowercased().hasSuffix(".png") ||
        urlString.lowercased().hasSuffix(".heic")

        if isImage {
            fileBadge.isHidden = true
            imageView.setKFImage(urlString: urlString)
        } else {
            fileBadge.isHidden = false
            imageView.image = UIImage(systemName: "doc")
            imageView.tintColor = GrayStyle.gray60.color
        }
    }
}
