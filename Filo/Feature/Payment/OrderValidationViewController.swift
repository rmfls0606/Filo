//
//  OrderValidationViewController.swift
//  Filo
//
//  Created by 이상민 on 2/5/26.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class OrderValidationViewController: BaseViewController {
    //MARK: - UI
    private let scrollView: UIScrollView = {
        let view = UIScrollView()
        view.alwaysBounceVertical = false
        view.delaysContentTouches = false
        view.canCancelContentTouches = false
        return view
    }()

    private let contentView = UIView()

    private let orderDateLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.title1
        label.textColor = GrayStyle.gray60.color
        return label
    }()

    private let orderCodeLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.caption1
        label.textColor = GrayStyle.gray75.color
        return label
    }()
    
    private let firstLineView: UIView = {
        let view = UIView()
        view.backgroundColor = Brand.deepTurquoise.color
        return view
    }()
    
    private let orderProductTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "주문 상품"
        label.font = .Pretendard.body1
        label.textColor = GrayStyle.gray60.color
        return label
    }()

    private let orderListTableView: UITableView = {
        let view = UITableView()
        view.rowHeight = UITableView.automaticDimension
        view.isScrollEnabled = false
        view.separatorStyle = .none
        view.register(OrderListTableViewCell.self, forCellReuseIdentifier: OrderListTableViewCell.identifier)
        return view
    }()
    
    private let secondLineView: UIView = {
        let view = UIView()
        view.backgroundColor = Brand.deepTurquoise.color
        return view
    }()
    
    private let paymentInfoContainer: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = true
        return view
    }()
    
    private let paymentInfoHeaderStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.spacing = 20
        view.distribution = .equalCentering
        view.isUserInteractionEnabled = true
        return view
    }()

    private let paymentInfoTitle: UILabel = {
        let label = UILabel()
        label.text = "결제 정보"
        label.font = .Pretendard.body1
        label.textColor = GrayStyle.gray60.color
        return label
    }()

    private let receiptButton: UIButton = {
        var config = UIButton.Configuration.plain()
        var attrs = AttributeContainer()
        attrs.font = .Pretendard.body2 ?? UIFont.systemFont(ofSize: 14)
        attrs.underlineStyle = .single
        attrs.foregroundColor = GrayStyle.gray75.color
        config.attributedTitle = AttributedString("영수증", attributes: attrs)
        config.contentInsets = .zero
        config.background.cornerRadius = .zero
        let button = UIButton(configuration: config)
        button.isUserInteractionEnabled = true
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        return button
    }()
    
    private let productPriceStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.spacing = 20
        view.distribution = .equalCentering
        return view
    }()

    private let productPriceTitle: UILabel = {
        let label = UILabel()
        label.text = "상품 금액"
        label.font = .Pretendard.body2
        label.textColor = GrayStyle.gray60.color
        return label
    }()

    private let productPriceLabel: UILabel = {
        let label = UILabel()
        label.text = "0원"
        label.font = .Pretendard.body2
        label.textColor = GrayStyle.gray60.color
        return label
    }()
    
    private let paymentPriceStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.spacing = 20
        view.distribution = .equalCentering
        return view
    }()

    private let paymentPriceTitle: UILabel = {
        let label = UILabel()
        label.text = "결제 금액"
        label.font = .Pretendard.body1
        label.textColor = GrayStyle.gray30.color
        return label
    }()

    private let paymentPriceLabel: UILabel = {
        let label = UILabel()
        label.text = "0원"
        label.font = .Pretendard.body1
        label.textColor = GrayStyle.gray30.color
        return label
    }()
    
    private let paymentMethodStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.spacing = 20
        view.distribution = .equalCentering
        return view
    }()

    private let paymentMethodTitle: UILabel = {
        let label = UILabel()
        label.text = "결제 수단"
        label.font = .Pretendard.body2
        label.textColor = GrayStyle.gray60.color
        return label
    }()

    private let paymentMethodLabel: UILabel = {
        let label = UILabel()
        label.text = "-"
        label.font = .Pretendard.body1
        label.textColor = GrayStyle.gray60.color
        return label
    }()
    
    //MARK: - Properties
    private let viewModel: OrderValidationViewModel
    private let disposeBag = DisposeBag()
    private var orderListHeightConstraint: Constraint?
    private var latestPaymentInfo: PaymentResponseDTO?
    private var latestReceipt: ReceiptOrderResponseDTO?
    
    override var prefersCustomTabBarHidden: Bool{
        return true
    }

    init(viewModel: OrderValidationViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    override func configureHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(orderDateLabel)
        contentView.addSubview(orderCodeLabel)
        contentView.addSubview(firstLineView)
        contentView.addSubview(orderProductTitleLabel)
    
        contentView.addSubview(orderListTableView)
        contentView.addSubview(secondLineView)
        contentView.addSubview(paymentInfoContainer)
        
        paymentInfoContainer.addSubview(paymentInfoHeaderStackView)
        paymentInfoHeaderStackView.addArrangedSubview(paymentInfoTitle)
        paymentInfoHeaderStackView.addArrangedSubview(receiptButton)
        
        paymentInfoContainer.addSubview(productPriceStackView)
        productPriceStackView.addArrangedSubview(productPriceTitle)
        productPriceStackView.addArrangedSubview(productPriceLabel)
        
        paymentInfoContainer.addSubview(paymentPriceStackView)
        paymentPriceStackView.addArrangedSubview(paymentPriceTitle)
        paymentPriceStackView.addArrangedSubview(paymentPriceLabel)
        
        paymentInfoContainer.addSubview(paymentMethodStackView)
        paymentMethodStackView.addArrangedSubview(paymentMethodTitle)
        paymentMethodStackView.addArrangedSubview(paymentMethodLabel)
    }

    override func configureLayout() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }
        
        orderDateLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        
        orderCodeLabel.snp.makeConstraints { make in
            make.top.equalTo(orderDateLabel.snp.bottom).offset(8)
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        
        firstLineView.snp.makeConstraints { make in
            make.top.equalTo(orderCodeLabel.snp.bottom).offset(20)
            make.height.equalTo(1)
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        
        orderProductTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(firstLineView.snp.bottom).offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        
        orderListTableView.snp.makeConstraints { make in
            make.top.equalTo(orderProductTitleLabel.snp.bottom)
            make.horizontalEdges.equalToSuperview()
            orderListHeightConstraint = make.height.equalTo(0).constraint
        }
        
        secondLineView.snp.makeConstraints { make in
            make.top.equalTo(orderListTableView.snp.bottom)
            make.height.equalTo(1)
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        
        paymentInfoContainer.snp.makeConstraints { make in
            make.top.equalTo(secondLineView.snp.bottom).offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(20)
        }
        
        paymentInfoHeaderStackView.snp.makeConstraints { make in
            make.top.horizontalEdges.equalToSuperview()
        }
        
        productPriceStackView.snp.makeConstraints { make in
            make.top.equalTo(paymentInfoHeaderStackView.snp.bottom).offset(20)
            make.horizontalEdges.equalToSuperview()
        }
        
        paymentPriceStackView.snp.makeConstraints { make in
            make.top.equalTo(productPriceStackView.snp.bottom).offset(20)
            make.horizontalEdges.equalToSuperview()
        }
        
        paymentMethodStackView.snp.makeConstraints { make in
            make.top.equalTo(paymentPriceStackView.snp.bottom).offset(12)
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    override func configureView() {
        navigationItem.title = "주문 상세"
        contentView.bringSubviewToFront(paymentInfoContainer)
        scrollView.panGestureRecognizer.cancelsTouchesInView = false
    }

    override func configureBind() {
        let input = OrderValidationViewModel.Input(
            viewWillAppear: rx.methodInvoked(#selector(UIViewController.viewWillAppear(_:))).map { _ in }
        )
        
        let output = viewModel.transform(input: input)

        output.receipt
            .drive(with: self) { owner, receipt in
                owner.latestReceipt = receipt
                let paidAt = receipt.orderItem?.paidAt.toOrderDateString() ?? "-"
                let orderCode = receipt.orderItem?.orderCode ?? "-"
                let price = receipt.orderItem?.filter?.price ?? 0
                owner.orderDateLabel.text = "\(paidAt)"
                owner.orderCodeLabel.text = "주문 번호 \(orderCode)"
                owner.paymentPriceLabel.text = "\(price.formattedDecimal())원"
            }            .disposed(by: disposeBag)

        output.orderFilter
            .compactMap { $0 }
            .map { [$0] }
            .drive(orderListTableView.rx.items(
                cellIdentifier: OrderListTableViewCell.identifier,
                cellType: OrderListTableViewCell.self
            )) { _, element, cell in
                cell.configure(orderFilter: element)
            }
            .disposed(by: disposeBag)
        
        output.paymentInfo
            .compactMap { $0 }
            .drive(with: self) { owner, payment in
                owner.latestPaymentInfo = payment
                owner.paymentMethodLabel.text = owner.formatPaymentMethod(payment)
            }
            .disposed(by: disposeBag)
        
        output.networkError
            .emit(with: self) { owner, error in
                owner.showAlert(title: "오류", message: error.errorDescription)
            }
            .disposed(by: disposeBag)

        orderListTableView.rx
            .observe(CGSize.self, "contentSize")
            .compactMap { $0?.height }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] height in
                self?.orderListHeightConstraint?.update(offset: height)
            })
            .disposed(by: disposeBag)

        orderListTableView.rx.itemSelected
            .withLatestFrom(output.orderFilter) { (_, filter) in filter }
            .compactMap { $0 }
            .bind(with: self) { owner, filter in
                guard let filterId = filter.id else { return }
                let vm = DetailViewModel(filterId: filterId)
                let vc = DetailViewController(viewModel: vm)
                owner.navigationController?.pushViewController(vc, animated: true)
            }
            .disposed(by: disposeBag)

        receiptButton.rx.tap
            .bind(with: self, onNext: { owner, _ in
                print("B")
                guard let receipt = owner.latestReceipt else { return }
                print("C")
                let vc = ReceiptViewController(receipt: receipt, payment: owner.latestPaymentInfo)
                owner.navigationController?.pushViewController(vc, animated: true)
            })
            .disposed(by: disposeBag)
    }

}

private extension OrderValidationViewController {
    func formatPaymentMethod(_ payment: PaymentResponseDTO) -> String {
        let method = payment.payMethod ?? ""
        if method.contains("card") || payment.cardName != nil {
            let card = payment.cardName ?? "카드"
            return card
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
}
