//
//  TodayAuthorImageCollectionViewCell.swift
//  Filo
//
//  Created by 이상민 on 1/22/26.
//

import UIKit
import SnapKit

final class TodayAuthorImageCollectionViewCell: BaseCollectionViewCell {
    
    private let authorImage: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.layer.cornerRadius = 8
        return view
    }()
    
    override func configureHierarchy() {
        contentView.addSubview(authorImage)
    }
    
    override func configureLayout() {
        authorImage.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func configure(urlString: String) {
        authorImage.setKFImage(urlString: urlString, targetSize: authorImage.bounds.size)
    }
}
