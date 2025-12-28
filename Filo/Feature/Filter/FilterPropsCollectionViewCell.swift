//
//  FilterPropsCollectionViewCell.swift
//  Filo
//
//  Created by 이상민 on 12/28/25.
//

import UIKit
import SnapKit

final class FilterPropsCollectionViewCell: BaseCollectionViewCell {
    //MARK: - UI
    private let filterIcon: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.tintColor = GrayStyle.gray75.color
        return view
    }()
    
    private let filterText: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.caption2
        label.textColor = GrayStyle.gray75.color
        label.textAlignment = .center
        return label
    }()
    
    override func configureHierarchy() {
        contentView.addSubview(filterIcon)
        contentView.addSubview(filterText)
    }
    
    override func configureLayout() {
        filterIcon.snp.makeConstraints { make in
            make.top.horizontalEdges.equalToSuperview()
        }
        
        filterText.snp.makeConstraints { make in
            make.top.equalTo(filterIcon.snp.bottom).offset(8)
            make.bottom.horizontalEdges.equalToSuperview()
        }
    }
    
    func configure(item: FilterProps){
        filterIcon.image = UIImage(named: item.rawValue)
        filterText.text = item.title
    }
}
