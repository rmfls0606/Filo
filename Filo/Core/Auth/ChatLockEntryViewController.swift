//
//  ChatLockEntryViewController.swift
//  Filo
//
//  Created by Codex on 3/12/26.
//

import UIKit
import SnapKit
import LocalAuthentication
import RxSwift
import RxCocoa

final class ChatLockEntryViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    private let viewDidAppearRelay = PublishRelay<Void>()
    private let biometricResultRelay = PublishRelay<Result<Void, DeviceSecurityAuthError>>()

    private let titleText: String
    private let messageText: String
    private let leadingAction: ChatLockLeadingAction
    private let showsCloseButton: Bool
    private let biometricAction: (() async -> Result<Void, DeviceSecurityAuthError>)?
    private let viewModel: ChatLockEntryViewModel

    private lazy var lockScreenView = ChatLockScreenView(
        title: titleText,
        message: messageText,
        leadingAction: leadingAction,
        showsCloseButton: showsCloseButton,
        isInteractive: true
    )

    var onSuccess: (() -> Void)?
    var onCancel: (() -> Void)?

    init(
        title: String,
        message: String,
        leadingAction: ChatLockLeadingAction,
        showsCloseButton: Bool,
        verifyPasscode: @escaping (String) -> Bool,
        biometricAction: (() async -> Result<Void, DeviceSecurityAuthError>)?
    ) {
        self.titleText = title
        self.messageText = message
        self.leadingAction = leadingAction
        self.showsCloseButton = showsCloseButton
        self.biometricAction = biometricAction
        self.viewModel = ChatLockEntryViewModel(
            leadingAction: leadingAction,
            verifyPasscode: verifyPasscode
        )
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    override func configureHierarchy() {
        view.addSubview(lockScreenView)
    }

    override func configureLayout() {
        lockScreenView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func configureBind() {
        let input = ChatLockEntryViewModel.Input(
            itemTapped: lockScreenView.itemTapped,
            closeTapped: lockScreenView.closeTapped,
            viewDidAppear: viewDidAppearRelay.asObservable(),
            biometricResult: biometricResultRelay.asObservable()
        )
        let output = viewModel.transform(input: input)

        output.filledCount
            .drive(with: self) { owner, count in
                owner.lockScreenView.updateDots(filledCount: count)
            }
            .disposed(by: disposeBag)

        output.requestBiometric
            .emit(with: self) { owner, _ in
                owner.runBiometricAuthentication()
            }
            .disposed(by: disposeBag)

        output.dismissSuccess
            .emit(with: self) { owner, _ in
                owner.dismiss(animated: true) { [weak owner] in
                    owner?.onSuccess?()
                }
            }
            .disposed(by: disposeBag)

        output.dismissCancel
            .emit(with: self) { owner, _ in
                owner.dismiss(animated: true) { [weak owner] in
                    owner?.onCancel?()
                }
            }
            .disposed(by: disposeBag)

        output.alert
            .emit(with: self) { owner, alert in
                owner.showAlert(title: alert.title, message: alert.message)
            }
            .disposed(by: disposeBag)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewDidAppearRelay.accept(())
    }

    private func runBiometricAuthentication() {
        guard let biometricAction else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            let result = await biometricAction()
            biometricResultRelay.accept(result)
        }
    }
}

private final class ChatLockEntryViewModel: ViewModelType {
    struct Input {
        let itemTapped: Observable<ChatLockScreenItem>
        let closeTapped: Observable<Void>
        let viewDidAppear: Observable<Void>
        let biometricResult: Observable<Result<Void, DeviceSecurityAuthError>>
    }

    struct Output {
        let filledCount: Driver<Int>
        let requestBiometric: Signal<Void>
        let dismissSuccess: Signal<Void>
        let dismissCancel: Signal<Void>
        let alert: Signal<ChatLockAlert>
    }

    private let disposeBag = DisposeBag()
    private let leadingAction: ChatLockLeadingAction
    private let verifyPasscode: (String) -> Bool

    init(
        leadingAction: ChatLockLeadingAction,
        verifyPasscode: @escaping (String) -> Bool
    ) {
        self.leadingAction = leadingAction
        self.verifyPasscode = verifyPasscode
    }

    func transform(input: Input) -> Output {
        let passcodeRelay = BehaviorRelay<String>(value: "")
        let requestBiometricRelay = PublishRelay<Void>()
        let dismissSuccessRelay = PublishRelay<Void>()
        let dismissCancelRelay = PublishRelay<Void>()
        let alertRelay = PublishRelay<ChatLockAlert>()

        let autoBiometricTrigger = input.viewDidAppear
            .take(1)
            .filter { [leadingAction] in leadingAction == .biometric }
            .map { _ in }

        Observable.merge(
            autoBiometricTrigger,
            input.itemTapped.compactMap { item -> Void? in
                guard case .biometric = item else { return nil }
                return ()
            }
        )
        .bind(to: requestBiometricRelay)
        .disposed(by: disposeBag)

        input.closeTapped
            .bind(to: dismissCancelRelay)
            .disposed(by: disposeBag)

        input.itemTapped
            .subscribe(onNext: { [weak self] item in
                guard let self else { return }
                var passcode = passcodeRelay.value

                switch item {
                case .digit(let number):
                    guard passcode.count < 4 else { return }
                    passcode.append(number)
                    passcodeRelay.accept(passcode)
                    guard passcode.count == 4 else { return }

                    if self.verifyPasscode(passcode) {
                        dismissSuccessRelay.accept(())
                    } else {
                        passcodeRelay.accept("")
                        alertRelay.accept(
                            ChatLockAlert(
                                title: "암호 입력",
                                message: "암호가 올바르지 않습니다."
                            )
                        )
                    }
                case .delete:
                    guard !passcode.isEmpty else { return }
                    passcode.removeLast()
                    passcodeRelay.accept(passcode)
                case .cancel:
                    dismissCancelRelay.accept(())
                case .biometric, .empty:
                    break
                }
            })
            .disposed(by: disposeBag)

        input.biometricResult
            .subscribe(onNext: { result in
                switch result {
                case .success:
                    dismissSuccessRelay.accept(())
                case .failure(let error):
                    guard error != .canceled else { return }
                    alertRelay.accept(
                        ChatLockAlert(
                            title: "생체 인증",
                            message: error.errorDescription ?? ""
                        )
                    )
                }
            })
            .disposed(by: disposeBag)

        return Output(
            filledCount: passcodeRelay
                .map(\.count)
                .distinctUntilChanged()
                .asDriver(onErrorJustReturn: 0),
            requestBiometric: requestBiometricRelay.asSignal(),
            dismissSuccess: dismissSuccessRelay.asSignal(),
            dismissCancel: dismissCancelRelay.asSignal(),
            alert: alertRelay.asSignal()
        )
    }
}

final class ChatLockScreenView: UIView {
    private let disposeBag = DisposeBag()
    private let itemTappedRelay = PublishRelay<ChatLockScreenItem>()
    private let closeTappedRelay = PublishRelay<Void>()

    var itemTapped: Observable<ChatLockScreenItem> { itemTappedRelay.asObservable() }
    var closeTapped: Observable<Void> { closeTappedRelay.asObservable() }
 
    private let titleText: String
    private let messageText: String
    private let leadingAction: ChatLockLeadingAction
    private let showsCloseButton: Bool
    private let isInteractive: Bool
    private var dotViews: [UIView] = []

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = GrayStyle.gray45.color
        return button
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.title1
        label.textColor = GrayStyle.gray30.color
        label.textAlignment = .center
        return label
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.body2
        label.textColor = GrayStyle.gray60.color
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let dotsStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.spacing = 16
        view.alignment = .center
        view.distribution = .fillEqually
        return view
    }()

    private let keypadStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 16
        view.distribution = .fillEqually
        return view
    }()
    
    private let topContentArea = UIView()
    
    private let headerStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 12
        view.alignment = .fill
        return view
    }()
    
    private let contentStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 28
        view.alignment = .center
        return view
    }()

    init(
        title: String,
        message: String,
        leadingAction: ChatLockLeadingAction,
        showsCloseButton: Bool,
        isInteractive: Bool
    ) {
        self.titleText = title
        self.messageText = message
        self.leadingAction = leadingAction
        self.showsCloseButton = showsCloseButton
        self.isInteractive = isInteractive
        super.init(frame: .zero)
        configureHierarchy()
        configureLayout()
        configureView()
        configureBind()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateDots(filledCount: Int) {
        for (index, dot) in dotViews.enumerated() {
            let filled = index < filledCount
            dot.backgroundColor = filled ? (Brand.brightTurquoise.color ?? .systemTeal) : .clear
            dot.layer.borderColor = (filled ? Brand.brightTurquoise.color : GrayStyle.gray60.color)?.cgColor
        }
    }

    private func configureHierarchy() {
        addSubview(closeButton)
        addSubview(topContentArea)
        addSubview(keypadStackView)
        
        topContentArea.addSubview(contentStackView)
        contentStackView.addArrangedSubview(headerStackView)
        contentStackView.addArrangedSubview(dotsStackView)
        headerStackView.addArrangedSubview(titleLabel)
        headerStackView.addArrangedSubview(messageLabel)

        for _ in 0..<4 {
            let dot = UIView()
            dot.layer.cornerRadius = 8
            dot.layer.borderWidth = 1
            dot.layer.borderColor = GrayStyle.gray60.color?.cgColor
            dot.backgroundColor = .clear
            dot.snp.makeConstraints { make in
                make.size.equalTo(16)
            }
            dotViews.append(dot)
            dotsStackView.addArrangedSubview(dot)
        }

        let rows: [[ChatLockScreenItem]] = [
            [.digit("1"), .digit("2"), .digit("3")],
            [.digit("4"), .digit("5"), .digit("6")],
            [.digit("7"), .digit("8"), .digit("9")],
            [leadingKeypadItem(), .digit("0"), .delete]
        ]

        for row in rows {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 16
            rowStack.alignment = .center
            rowStack.distribution = .equalSpacing
            for item in row {
                rowStack.addArrangedSubview(makeButton(for: item))
            }
            keypadStackView.addArrangedSubview(rowStack)
        }
    }

    private func configureLayout() {
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).inset(12)
            make.trailing.equalToSuperview().inset(20)
            make.size.equalTo(28)
        }

        keypadStackView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(360)
            make.bottom.equalTo(safeAreaLayoutGuide).inset(28)
        }

        topContentArea.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide)
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalTo(keypadStackView.snp.top)
        }
        
        contentStackView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.horizontalEdges.equalToSuperview().inset(28)
        }
    }

    private func configureView() {
        backgroundColor = GrayStyle.gray100.color
        titleLabel.text = titleText
        messageLabel.text = messageText
        closeButton.isHidden = !showsCloseButton
        updateDots(filledCount: 0)
    }

    private func configureBind() {
        closeButton.rx.tap
            .bind(to: closeTappedRelay)
            .disposed(by: disposeBag)
    }

    private func makeButton(for item: ChatLockScreenItem) -> UIView {
        switch item {
        case .empty:
            let view = UIView()
            view.snp.makeConstraints { make in
                make.width.equalTo(80)
                make.height.equalTo(80)
            }
            return view
        default:
            let button = CircularKeypadButton(type: .system)
            button.backgroundColor = GrayStyle.gray90.color
            button.setTitleColor(GrayStyle.gray30.color, for: .normal)
            button.titleLabel?.font = .Pretendard.title1
            button.snp.makeConstraints { make in
                make.size.equalTo(80)
            }

            switch item {
            case .digit(let number):
                button.setTitle(number, for: .normal)
            case .biometric:
                button.setImage(UIImage(systemName: biometricSymbolName()), for: .normal)
                button.tintColor = GrayStyle.gray30.color
            case .cancel:
                button.setTitle("취소", for: .normal)
                button.titleLabel?.font = .Pretendard.body1
            case .delete:
                button.setImage(UIImage(systemName: "delete.left"), for: .normal)
                button.tintColor = GrayStyle.gray30.color
            case .empty:
                break
            }

            button.isUserInteractionEnabled = isInteractive
            if isInteractive {
                button.rx.tap
                    .map { item }
                    .bind(to: itemTappedRelay)
                    .disposed(by: disposeBag)
            }
            return button
        }
    }

    private func biometricSymbolName() -> String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch context.biometryType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        default:
            return "lock.circle"
        }
    }

    private func leadingKeypadItem() -> ChatLockScreenItem {
        switch leadingAction {
        case .biometric:
            return .biometric
        case .cancel:
            return .cancel
        case .empty:
            return .empty
        }
    }
}

private final class CircularKeypadButton: UIButton {
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = min(bounds.width, bounds.height) / 2
        clipsToBounds = true
    }
}
