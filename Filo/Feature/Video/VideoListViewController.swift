import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class VideoListViewController: BaseViewController {
    override var prefersCustomTabBarHidden: Bool { true }

    private let viewModel: VideoListViewModel
    private let disposeBag = DisposeBag()
    private var currentItems: [VideoResponseDTO] = []

    private let tableView: UITableView = {
        let view = UITableView()
        view.register(VideoListTableViewCell.self, forCellReuseIdentifier: VideoListTableViewCell.identifier)
        view.separatorStyle = .none
        view.backgroundColor = .clear
        view.rowHeight = UITableView.automaticDimension
        view.estimatedRowHeight = 96
        return view
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .large)
        view.hidesWhenStopped = true
        return view
    }()

    private let appendLoadingIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.hidesWhenStopped = true
        return view
    }()

    init(viewModel: VideoListViewModel = VideoListViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    override func configureHierarchy() {
        view.addSubview(tableView)
        view.addSubview(loadingIndicator)
        view.addSubview(appendLoadingIndicator)
    }

    override func configureLayout() {
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        loadingIndicator.snp.makeConstraints { make in
            make.center.equalTo(view.safeAreaLayoutGuide)
        }

        appendLoadingIndicator.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(8)
        }
    }

    override func configureView() {
        navigationItem.title = "VIDEO"
    }

    override func configureBind() {
        let initialLoad = Observable.just(())

        let willDisplayTrigger = tableView.rx.willDisplayCell
            .compactMap { [weak self] _, indexPath -> Void? in
                guard let self else { return nil }
                let threshold = max(0, self.currentItems.count - 3)
                return indexPath.row >= threshold ? () : nil
            }

        let prefetchTrigger = tableView.rx.prefetchRows
            .compactMap { [weak self] indexPaths -> Void? in
                guard let self else { return nil }
                let rows = indexPaths.map { $0.row }
                guard let maxRow = rows.max() else { return nil }
                let threshold = max(0, self.currentItems.count - 5)
                return maxRow >= threshold ? () : nil
            }

        let loadNextPage = Observable.merge(willDisplayTrigger, prefetchTrigger)
            .throttle(.milliseconds(250), scheduler: MainScheduler.instance)

        let input = VideoListViewModel.Input(
            initialLoad: initialLoad,
            loadNextPage: loadNextPage,
            selectedVideo: tableView.rx.modelSelected(VideoResponseDTO.self).asObservable()
        )

        let output = viewModel.transform(input: input)

        output.videos
            .drive(tableView.rx.items(
                cellIdentifier: VideoListTableViewCell.identifier,
                cellType: VideoListTableViewCell.self
            )) { _, item, cell in
                cell.configure(item)
            }
            .disposed(by: disposeBag)

        output.videos
            .drive(with: self) { owner, items in
                owner.currentItems = items
            }
            .disposed(by: disposeBag)

        output.isInitialLoading
            .drive(with: self) { owner, isLoading in
                isLoading ? owner.loadingIndicator.startAnimating() : owner.loadingIndicator.stopAnimating()
            }
            .disposed(by: disposeBag)

        output.isAppending
            .drive(with: self) { owner, isLoading in
                isLoading ? owner.appendLoadingIndicator.startAnimating() : owner.appendLoadingIndicator.stopAnimating()
            }
            .disposed(by: disposeBag)

        output.selectedVideo
            .drive(with: self) { owner, video in
                let vc = VideoPlayerViewController(videoId: video.videoId, initialIsLiked: video.isLiked)
                owner.navigationController?.pushViewController(vc, animated: true)
            }
            .disposed(by: disposeBag)

        output.networkError
            .emit(onNext: { [weak self] error in
                self?.showAlert(title: "오류", message: error.errorDescription)
            })
            .disposed(by: disposeBag)
    }
}
