//
//  OrderListTableViewCell.swift
//  Filo
//
//  Created by 이상민 on 2/4/26.
//

import UIKit
import SnapKit

final class OrderListTableViewCell: BaseTableViewCell {
    private let productContainer: UIView = {
        let view = UIView()
        return view
    }()
    
    private let productImage: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        return view
    }()
    
    private let productInfoStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 8
        return view
    }()
    
    private let productName: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.body2
        label.textColor = GrayStyle.gray45.color
        label.numberOfLines = 2
        return label
    }()
    
    private let productContent: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.body2
        label.textColor = GrayStyle.gray60.color
        label.numberOfLines = 2
        return label
    }()
    
    private let productPrice: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.body2
        label.textColor = GrayStyle.gray45.color
        return label
    }()
    
    override func configureHierarchy() {
        contentView.addSubview(productContainer)
        productContainer.addSubview(productImage)
        productContainer.addSubview(productInfoStackView)
        productInfoStackView.addArrangedSubview(productName)
        productInfoStackView.addArrangedSubview(productContent)
        productContainer.addSubview(productPrice)
    }
    
    override func configureLayout() {
        productContainer.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(20)
            make.verticalEdges.equalToSuperview().inset(16)
        }
        
        productImage.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
            make.size.equalTo(80)
            make.bottom.lessThanOrEqualToSuperview()
        }
        
        productInfoStackView.snp.makeConstraints { make in
            make.leading.equalTo(productImage.snp.trailing).offset(12)
            make.top.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }
        
        productName.snp.makeConstraints { make in
            make.top.horizontalEdges.equalToSuperview()
        }
        
        productPrice.snp.makeConstraints { make in
            make.leading.greaterThanOrEqualTo(productInfoStackView.snp.trailing).offset(12)
            make.top.trailing.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }
        
        productPrice.setContentHuggingPriority(.defaultLow, for: .horizontal)
        productPrice.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
    
    override func configureView() {
        selectionStyle = .none
    }
    
    func configure(product: FilterResponseDTO){
        productImage.setKFImage(urlString: product.files[1])
        productName.text = product.title
        productContent.text = product.description
        productPrice.text = "\(product.price.formattedDecimal())원"
    }

    func configure(orderFilter: FilterSummaryResponseDTO_Order){
        productImage.setKFImage(urlString: orderFilter.files[1])
        productName.text = orderFilter.title
        productContent.text = orderFilter.description
        productPrice.text = "\(orderFilter.price.formattedDecimal())원"
    }
    
    func configure(order: OrderResponseDTO) {
        guard let filter = order.filter else {
            productImage.image = nil
            productName.text = "상품 정보를 불러올 수 없습니다."
            productContent.text = nil
            productPrice.text = nil
            return
        }
        configure(orderFilter: filter)
    }
}
