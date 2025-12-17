//
//  FilterSectionView.swift
//  Filo
//
//  Created by 이상민 on 12/18/25.
//

import UIKit
import SnapKit

final class FilterSectionView: BaseView{
    private let titleView: FilterTitleView
    private let contentView: UIView
    
    init(titleView: FilterTitleView, contentView: UIView) {
        self.titleView = titleView
        self.contentView = contentView
        
        super.init(frame: .zero)
    }
    
    override func configureHierarchy() {
        addSubview(titleView)
        addSubview(contentView)
    }
    
    override func configureLayout() {
        titleView.snp.makeConstraints { make in
            make.top.horizontalEdges.equalToSuperview()
        }
        
        contentView.snp.makeConstraints { make in
            make.top.equalTo(titleView.snp.bottom).offset(16)
            make.horizontalEdges.bottom.equalToSuperview()
        }
    }
}
