//
//  FilterTitleView.swift
//  Filo
//
//  Created by 이상민 on 12/17/25.
//

import UIKit
import SnapKit

final class FilterTitleView: BaseView{
    let title: String
    
    init(title: String) {
        self.title = title
        
        super.init(frame: .zero)
    }
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = title
        label.font = .Pretendard.body1
        label.textColor = GrayStyle.gray60.color
        return label
    }()
    
    override func configureHierarchy() {
        addSubview(titleLabel)
    }
    
    override func configureLayout() {
        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
