//
//  PurchaseHistoryViewController.swift
//  Filo
//
//  Created by 이상민 on 2/8/26.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class PurchaseHistoryViewController: BaseViewController {
    private let viewModel: PurchaseHistoryViewModel
    private let disposeBag = DisposeBag()
    private let selectedOrderRelay = PublishRelay<OrderResponseDTO>()
    private var sections: [OrderSection] = []
    
    private let tableView: UITableView = {
        let view = UITableView()
        view.rowHeight = UITableView.automaticDimension
        view.estimatedRowHeight = 120
        view.separatorStyle = .none
        view.register(OrderListTableViewCell.self, forCellReuseIdentifier: OrderListTableViewCell.identifier)
        view.backgroundColor = .clear
        view.contentInset.bottom = CustomTabBarView.height + 12
        view.verticalScrollIndicatorInsets.bottom = CustomTabBarView.height + 12
        return view
    }()
    
    init(viewModel: PurchaseHistoryViewModel = PurchaseHistoryViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func configureView() {
        view.backgroundColor = GrayStyle.gray100.color
        navigationItem.title = "구매내역"
    }
    
    override func configureHierarchy() {
        view.addSubview(tableView)
    }
    
    override func configureLayout() {
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    override func configureBind() {
        tableView.dataSource = self
        tableView.rx.setDelegate(self)
            .disposed(by: disposeBag)
        
        let input = PurchaseHistoryViewModel.Input(
            viewWillAppear: rx.methodInvoked(#selector(UIViewController.viewWillAppear(_:))).map { _ in },
            selectedOrder: selectedOrderRelay.asObservable()
        )
        
        let output = viewModel.transform(input: input)
        
        output.orders
            .drive(with: self) { owner, orders in
                owner.sections = owner.makeSections(from: orders)
                owner.tableView.reloadData()
            }
            .disposed(by: disposeBag)
        
        output.receipt
            .emit(with: self) { owner, receipt in
                let vm = OrderValidationViewModel(receipt: receipt)
                let vc = OrderValidationViewController(viewModel: vm)
                owner.navigationController?.pushViewController(vc, animated: true)
            }
            .disposed(by: disposeBag)
        
        output.networkError
            .emit(with: self) { owner, error in
                owner.showAlert(title: "오류", message: error.errorDescription)
            }
            .disposed(by: disposeBag)
        
        tableView.rx.itemSelected
            .compactMap { [weak self] indexPath -> OrderResponseDTO? in
                guard let self,
                      sections.indices.contains(indexPath.section),
                      sections[indexPath.section].items.indices.contains(indexPath.row) else {
                    return nil
                }
                return sections[indexPath.section].items[indexPath.row]
            }
            .bind(to: selectedOrderRelay)
            .disposed(by: disposeBag)
    }
}

private extension PurchaseHistoryViewController {
    struct OrderSection {
        let title: String
        let items: [OrderResponseDTO]
    }
    
    func makeSections(from orders: [OrderResponseDTO]) -> [OrderSection] {
        let grouped = Dictionary(grouping: orders) { order in
            order.paidAt.toOrderDateString()
        }
        let sortedKeys = grouped.keys.sorted { $0 > $1 }
        return sortedKeys.map { key in
            let items = grouped[key] ?? []
            return OrderSection(title: key, items: items)
        }
    }
}

extension PurchaseHistoryViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: OrderListTableViewCell.identifier,
            for: indexPath
        ) as? OrderListTableViewCell else {
            return UITableViewCell()
        }
        let order = sections[indexPath.section].items[indexPath.row]
        cell.configure(order: order)
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let container = UIView()
        let label = UILabel()
        label.font = .Pretendard.body1
        label.textColor = GrayStyle.gray60.color
        label.text = sections[section].title
        container.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(6)
            make.top.equalToSuperview().inset(10)
        }
        return container
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        40
    }
}
