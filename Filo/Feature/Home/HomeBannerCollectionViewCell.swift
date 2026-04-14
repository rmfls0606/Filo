//
//  HomeBannerCollectionViewCell.swift
//  Filo
//
//  Created by 이상민 on 01/23/26.
//

import UIKit
import SnapKit

final class HomeBannerCollectionViewCell: BaseCollectionViewCell {
    private let bannerImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.layer.cornerRadius = 12
        return view
    }()

    override func configureHierarchy() {
        contentView.addSubview(bannerImageView)
    }

    override func configureLayout() {
        bannerImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func configure(urlString: String) {
        bannerImageView.setKFImage(urlString: urlString, targetSize: bannerImageView.bounds.size)
    }
}
