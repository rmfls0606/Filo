//
//  PaymentViewController.swift
//  Filo
//
//  Created by 이상민 on 2/4/26.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import iamport_ios

final class PaymentViewController: BaseViewController {
    //MARK: - UI
    private let scrollView: UIScrollView = {
        let view = UIScrollView()
        view.alwaysBounceVertical = false
        return view
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        return view
    }()
    
    private let orderTitle: UILabel = {
        let label = UILabel()
        label.text = "주문 내역"
        label.font = .Pretendard.body1
        label.textColor = GrayStyle.gray60.color
        return label
    }()
    
    private let orderListTableView: UITableView = {
        let view = UITableView()
        view.rowHeight = UITableView.automaticDimension
        view.isScrollEnabled = false
        view.register(OrderListTableViewCell.self, forCellReuseIdentifier: OrderListTableViewCell.identifier)
        return view
    }()
    
    private let firstLineView: UIView = {
        let view = UIView()
        view.backgroundColor = Brand.deepTurquoise.color
        return view
    }()
    
    private let totalPriceContrainer: UIView = {
        let view = UIView()
        view.backgroundColor = Brand.blackTurquoise.color
        return view
    }()
    
    private let totalPriceTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "결제 금액"
        label.font = .Pretendard.body1
        label.textColor = GrayStyle.gray60.color
        return label
    }()
    
    private let orderPriceStackView: UIStackView = {
        let view = UIStackView()
        view.spacing = 12
        view.axis = .horizontal
        view.distribution = .equalCentering
        return view
    }()
    
    private let orderPriceTitleLable: UILabel = {
        let label = UILabel()
        label.text = "주문 금액"
        label.font = .Pretendard.body1
        label.textColor = GrayStyle.gray30.color
        return label
    }()
    
    private let orderPriceLabel: UILabel = {
        let label = UILabel()
        label.text = "0원"
        label.font = .Pretendard.body1
        label.textColor = GrayStyle.gray30.color
        return label
    }()
    
    private let productPriceStackView: UIStackView = {
        let view = UIStackView()
        view.spacing = 12
        view.axis = .horizontal
        view.distribution = .equalCentering
        return view
    }()
    
    private let productPriceTitleLable: UILabel = {
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
        label.textColor = GrayStyle.gray45.color
        return label
    }()
    
    private let totalPriceStackView: UIStackView = {
        let view = UIStackView()
        view.spacing = 12
        view.axis = .horizontal
        view.distribution = .equalCentering
        return view
    }()
    
    private let totalPriceTitleLable: UILabel = {
        let label = UILabel()
        label.text = "최종 결제 금액"
        label.font = .Pretendard.title1
        label.textColor = GrayStyle.gray30.color
        return label
    }()
    
    private let totalPriceLabel: UILabel = {
        let label = UILabel()
        label.text = "0원"
        label.font = .Pretendard.title1
        label.textColor = GrayStyle.gray30.color
        return label
    }()
    
    private let buyButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "결제하기"
        config.baseBackgroundColor = Brand.brightTurquoise.color
        config.baseForegroundColor = GrayStyle.gray30.color
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .Pretendard.body1
            return outgoing
        }
        let button = UIButton(configuration: config)
        return button
    }()
    
    //MARK: - Properties
    private let viewModel: PaymentViewModel
    private let disposeBag = DisposeBag()
    private var orderListHeightConstraint: Constraint?
    
    override var prefersCustomTabBarHidden: Bool{
        return true
    }
    
    init(viewModel: PaymentViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    override func configureHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(orderTitle)
        contentView.addSubview(orderListTableView)
        contentView.addSubview(firstLineView)
        contentView.addSubview(totalPriceTitleLabel)
        contentView.addSubview(totalPriceContrainer)
        totalPriceContrainer.addSubview(orderPriceStackView)
        orderPriceStackView.addArrangedSubview(orderPriceTitleLable)
        orderPriceStackView.addArrangedSubview(orderPriceLabel)
        totalPriceContrainer.addSubview(productPriceStackView)
        productPriceStackView.addArrangedSubview(productPriceTitleLable)
        productPriceStackView.addArrangedSubview(productPriceLabel)
        totalPriceContrainer.addSubview(totalPriceStackView)
        totalPriceStackView.addArrangedSubview(totalPriceTitleLable)
        totalPriceStackView.addArrangedSubview(totalPriceLabel)
        contentView.addSubview(buyButton)
    }
    
    override func configureLayout() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        contentView.snp.makeConstraints { make in
            make.width.equalTo(scrollView.frameLayoutGuide)
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.height.greaterThanOrEqualTo(scrollView.frameLayoutGuide)
        }
        
        orderTitle
            .snp.makeConstraints { make in
            make.top.horizontalEdges.equalToSuperview().inset(20)
        }
        
        orderListTableView.snp.makeConstraints { make in
            make.top.equalTo(orderTitle.snp.bottom).offset(20)
            make.horizontalEdges.equalToSuperview()
            orderListHeightConstraint = make.height.equalTo(0).constraint
        }
        
        firstLineView.snp.makeConstraints { make in
            make.top.equalTo(orderListTableView.snp.bottom)
            make.height.equalTo(1)
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        
        totalPriceTitleLabel.snp.makeConstraints { make in
            make.top.greaterThanOrEqualTo(firstLineView.snp.bottom).offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        
        totalPriceContrainer.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.top.equalTo(totalPriceTitleLabel.snp.bottom).offset(20)
            make.bottom.equalTo(buyButton.snp.top).offset(-16)
        }
        
        orderPriceStackView.snp.makeConstraints { make in
            make.top.horizontalEdges.equalToSuperview().inset(20)
        }
        
        productPriceStackView.snp.makeConstraints { make in
            make.top.equalTo(orderPriceStackView.snp.bottom).offset(8)
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        
        totalPriceStackView.snp.makeConstraints { make in
            make.top.equalTo(productPriceStackView.snp.bottom).offset(20)
            make.horizontalEdges.bottom.equalToSuperview().inset(20)
        }
        
        buyButton.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(20)
            make.bottom.equalToSuperview()
        }
    }
    
    override func configureView() {
        navigationItem.title = "결제하기"
        orderListTableView.separatorStyle = .none
    }
    
    override func configureBind() {
        let input = PaymentViewModel.Input(
            buyButtonTapped: buyButton.rx.tap
        )
        let output = viewModel.transform(input: input)
        
        output.orderItems
            .drive(orderListTableView.rx.items(cellIdentifier: OrderListTableViewCell.identifier, cellType: OrderListTableViewCell.self)){ index, element, cell in
                cell.configure(product: element)
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
        
        output.totalPrice
            .drive(with: self){ owner, total in
                owner.orderPriceLabel.text = "\(total.formattedDecimal())원"
                owner.productPriceLabel.text = "\(total.formattedDecimal())원"
                owner.totalPriceLabel.text = "\(total.formattedDecimal())원"
                var config = owner.buyButton.configuration
                config?.title = "\(total.formattedDecimal())원 결제하기"
                owner.buyButton.configuration = config
            }
            .disposed(by: disposeBag)
        
        output.paymentInfo
            .drive(with: self){ owner, paymentInfo in
                let payment = IamportPayment(
                    pg: PG.html5_inicis.makePgRawName(pgId: "INIpayTest"),
                    merchant_uid: paymentInfo.merchantUId,
                    amount: paymentInfo.totalPrice)
                payment.pay_method = PayMethod.card.rawValue
                payment.name = paymentInfo.productName
                payment.buyer_name = paymentInfo.buyerName
                payment.app_scheme = PaymentConfig.appScheme
                
                Iamport.shared.payment(
                    viewController: owner,
                    userCode: PaymentConfig.userCode,
                    payment: payment
                ) { response in
                    print(String(describing: response))
                }
            }
            .disposed(by: disposeBag)
    }
}
