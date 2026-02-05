//
//  BannerWebViewController.swift
//  Filo
//
//  Created by 이상민 on 2/5/26.
//

import UIKit
import WebKit
import SnapKit
import RxSwift
import RxCocoa

final class BannerWebViewController: BaseViewController, WKScriptMessageHandler {
    //MARK: - UI
    private let contentController = WKUserContentController()

    private lazy var webView: WKWebView = {
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        let view = WKWebView(frame: .zero, configuration: config)
        view.allowsBackForwardNavigationGestures = true
        return view
    }()

    override var prefersCustomTabBarHidden: Bool {
        true
    }

    //MARK: - Properties
    private let viewModel: BannerWebViewModel
    private let disposeBag = DisposeBag()
    
    init(viewModel: BannerWebViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        contentController.removeScriptMessageHandler(forName: "click_attendance_button")
        contentController.removeScriptMessageHandler(forName: "complete_attendance")
    }

    override func configureHierarchy() {
        view.addSubview(webView)
    }

    override func configureLayout() {
        webView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func configureView() {
        navigationItem.title = "출석하기"
        //메세지 핸들러 등록
        contentController.add(self, name: "click_attendance_button")
        contentController.add(self, name: "complete_attendance")
    }
    
    override func configureBind() {
        let input = BannerWebViewModel.Input()
        
        let output = viewModel.transform(input: input)
        
        output.bannerData
            .drive(with: self){ owner, banner in
                guard let url = URL(string: NetworkConfig.webBaseURL + banner.payload.value) else{
                    owner.showAlert(title: "오류", message: "잘못된 배너 URL 입니다.")
                    return
                }
                
                var request = URLRequest(url: url)
                request.setValue(NetworkConfig.apiKey, forHTTPHeaderField: "SeSACKey")
                owner.webView.load(request)
            }
            .disposed(by: disposeBag)
    }

    //동작 흐름
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "click_attendance_button":
            Task { [weak self] in
                guard let self else { return }
                do {
                    let accessToken = try await BannerWebViewModel.validAccessToken()
                    let escapedToken = accessToken
                        .replacingOccurrences(of: "\\", with: "\\\\")
                        .replacingOccurrences(of: "'", with: "\\'")
                    _ = try await self.webView.evaluateJavaScript("requestAttendance('\(escapedToken)')")
                } catch {
                    self.showAlert(title: "오류", message: "웹뷰 통신에 실패했습니다.")
                }
            }
        case "complete_attendance":
            let count: String
            if let number = message.body as? Int {
                count = "\(number)번째 "
            } else if let numberString = message.body as? String, !numberString.isEmpty {
                count = "\(numberString)번째 "
            } else {
                count = ""
            }
            showAlert(title: "출석 완료", message: "\(count)출석이 완료되었습니다.") { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
        default:
            break
        }
    }

}
