//
//  ChatRoomListViewController.swift
//  Filo
//
//  Created by 이상민 on 2/6/26.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class ChatRoomListViewController: BaseViewController {
    //MARK: - View
    private let tableView: UITableView = {
        let view = UITableView()
        view.separatorStyle = .none
        view.backgroundColor = .clear
        view.rowHeight = 80
        view.register(ChatRoomListTableViewCell.self, forCellReuseIdentifier: ChatRoomListTableViewCell.identifier)
        return view
    }()

    //MARK: - Prroperties
    private let viewModel: ChatRoomListViewModel
    private let disposeBag = DisposeBag()

    override var prefersCustomTabBarHidden: Bool { true }

    init(viewModel: ChatRoomListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    override func configureHierarchy() {
        view.addSubview(tableView)
    }

    override func configureLayout() {
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }

    override func configureView() {
        title = "채팅 목록"
    }

    override func configureBind() {
        let input = ChatRoomListViewModel.Input(
            viewWillAppear: rx.methodInvoked(#selector(UIViewController.viewWillAppear)).map { _ in },
            viewWillDisappear: rx.methodInvoked(#selector(UIViewController.viewWillDisappear)).map { _ in }
        )

        let output = viewModel.transform(input: input)

        output.chatRoomList
            .drive(tableView.rx.items(cellIdentifier: ChatRoomListTableViewCell.identifier, cellType: ChatRoomListTableViewCell.self)){ [weak self] _, element, cell in
                guard let self else { return }
                let cached = element.opponentId.flatMap { ChatLocalStore.shared.fetchUser(userId: $0) }
                cell.configure(summary: element, cachedUser: cached)
            }
            .disposed(by: disposeBag)

        tableView.rx.modelSelected(ChatRoomSummaryEntity.self)
            .subscribe(onNext: { [weak self] room in
                guard let self else { return }
                let opponent = room.opponentId.flatMap { ChatLocalStore.shared.fetchUser(userId: $0) }
                let vm = ChatRoomViewModel(roomId: room.roomId, opponentId: room.opponentId)
                let vc = ChatRoomViewController(viewModel: vm, title: opponent?.nick)
                self.navigationController?.pushViewController(vc, animated: true)
            })
            .disposed(by: disposeBag)

        output.networkError
            .emit(with: self) { owner, error in
                owner.showAlert(title: "오류", message: error.errorDescription)
            }
            .disposed(by: disposeBag)
    }
}
