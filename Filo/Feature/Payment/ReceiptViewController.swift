//
//  ReceiptViewController.swift
//  Filo
//
//  Created by 이상민 on 2/5/26.
//

import UIKit
import SnapKit

final class ReceiptViewController: BaseViewController {
    private let receipt: ReceiptOrderResponseDTO?
    private let order: OrderResponseDTO?
    private let payment: PaymentResponseDTO?

    private let scrollView: UIScrollView = {
        let view = UIScrollView()
        view.alwaysBounceVertical = true
        return view
    }()
    
    private let contentView = UIView()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "영수증"
        label.font = .Pretendard.title1
        label.textColor = GrayStyle.gray30.color
        return label
    }()

    private let listStack: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 14
        return view
    }()

    init(receipt: ReceiptOrderResponseDTO, payment: PaymentResponseDTO? = nil) {
        self.receipt = receipt
        self.order = nil
        self.payment = payment
        super.init(nibName: nil, bundle: nil)
    }
    
    init(order: OrderResponseDTO, payment: PaymentResponseDTO) {
        self.receipt = nil
        self.order = order
        self.payment = payment
        super.init(nibName: nil, bundle: nil)
    }

    override func configureHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(listStack)
    }

    override func configureLayout() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        
        listStack.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(20)
        }
    }

    override func configureView() {
        navigationItem.title = "영수증"
        if let receipt {
            buildRows(order: receipt.orderItem, paymentId: receipt.paymentId, payment: payment)
            return
        }
        
        if let order, let payment {
            buildRows(order: order, paymentId: payment.impUid, payment: payment)
        }
    }
}

private extension ReceiptViewController {
    func buildRows(order: OrderResponseDTO?, paymentId: String?, payment: PaymentResponseDTO?) {
        listStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        let orderCode = order?.orderCode ?? "-"
        let buyer = payment?.buyerName ?? "-"
        let product = order?.filter?.title ?? "-"
        let cardType = payment?.cardName ?? "-"
        let cardNumber = payment?.cardNumber ?? "-"
        let installment = formatInstallment(payment?.cardQuota)
        let status = payment?.status ?? "-"
        let approvalNumber = payment?.applyNum ?? "-"
        let amount = payment?.amount ?? order?.filter?.price ?? 0
        let supplyAmount = amount
        let taxFree = 0
        let vat = 0
        let total = amount
        
        let rows: [(String, String)] = [
            ("주문번호", orderCode),
            ("구매자", buyer),
            ("구매상품", product),
            ("카드종류", cardType),
            ("카드번호", cardNumber),
            ("할부", installment),
            ("결제상태", status),
            ("승인번호", approvalNumber),
            ("승인 공급가액", "\(supplyAmount.formattedDecimal())원"),
            ("면세가액", "\(taxFree.formattedDecimal())원"),
            ("부가세", "\(vat.formattedDecimal())원"),
            ("합계", "\(total.formattedDecimal())원")
        ]
        
        rows.enumerated().forEach { index, row in
            listStack.addArrangedSubview(makeRow(title: row.0, value: row.1))
            
            if index == 2 || index == 7 || index == rows.count - 1 {
                listStack.addArrangedSubview(makeSeparator())
            }
        }
    }
    
    func formatPaymentMethod(_ payment: PaymentResponseDTO?) -> String {
        guard let payment else { return "-" }
        let method = payment.payMethod ?? ""
        if method.contains("card") || payment.cardName != nil {
            return payment.cardName ?? "카드"
        }
        if method.contains("vbank") {
            return "가상계좌"
        }
        if method.contains("trans") || method.contains("bank") {
            return payment.bankName ?? "계좌이체"
        }
        if method.contains("phone") {
            return "휴대폰"
        }
        return method.isEmpty ? "-" : method
    }
    
    func formatInstallment(_ quota: Int?) -> String {
        guard let quota else { return "-" }
        return quota == 0 ? "일시불" : "\(quota)개월"
    }
    
    func makeRow(title: String, value: String) -> UIView {
        let container = UIView()
        let titleLabel = UILabel()
        titleLabel.font = .Pretendard.body2
        titleLabel.textColor = GrayStyle.gray60.color
        titleLabel.text = title
        
        let valueLabel = UILabel()
        valueLabel.font = .Pretendard.body2
        valueLabel.textColor = GrayStyle.gray30.color
        valueLabel.textAlignment = .right
        valueLabel.numberOfLines = 2
        valueLabel.text = value
        
        container.addSubview(titleLabel)
        container.addSubview(valueLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
        }
        
        valueLabel.snp.makeConstraints { make in
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(12)
            make.trailing.top.bottom.equalToSuperview()
        }
        return container
    }
    
    func makeSeparator() -> UIView {
        let view = UIView()
        view.backgroundColor = GrayStyle.gray90.color
        view.snp.makeConstraints { make in
            make.height.equalTo(1)
        }
        return view
    }
}
