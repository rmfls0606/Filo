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
    private let trailingView: UIView?
    
    init(title: String, trailingView: UIView? = nil) {
        self.title = title
        self.trailingView = trailingView
        
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
        if let trailingView = trailingView {
            addSubview(trailingView)
        }
    }
    
    override func configureLayout() {
        titleLabel.snp.makeConstraints { make in
            make.leading.verticalEdges.equalToSuperview()
        }
        
        if let trailingView = trailingView {
            trailingView.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.trailing.equalToSuperview()
                make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(8)
            }
        } else {
            titleLabel.snp.makeConstraints { make in
                make.trailing.equalToSuperview()
            }
        }
    }
    
    func setTrailingHidden(_ hidden: Bool){
        trailingView?.isHidden = hidden
    }
}
