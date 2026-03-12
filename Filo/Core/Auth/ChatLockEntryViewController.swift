//
//  ChatLockEntryViewController.swift
//  Filo
//
//  Created by Codex on 3/12/26.
//

import UIKit
import SnapKit
import LocalAuthentication

final class ChatLockEntryViewController: BaseViewController {
    private enum KeypadItem {
        case digit(String)
        case biometric
        case cancel
        case delete
        case empty
    }

    enum LeadingAction {
        case biometric
        case cancel
        case empty
    }

    private let titleText: String
    private let messageText: String
    private let leadingAction: LeadingAction
    private let showsCloseButton: Bool
    private let verifyPasscode: (String) -> Bool
    private let biometricAction: (() async -> Result<Void, DeviceSecurityAuthError>)?
    private var enteredPasscode = ""
    private var hasAttemptedBiometric = false
    private var dotViews: [UIView] = []

    var onSuccess: (() -> Void)?
    var onCancel: (() -> Void)?

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

    init(
        title: String,
        message: String,
        leadingAction: LeadingAction,
        showsCloseButton: Bool,
        verifyPasscode: @escaping (String) -> Bool,
        biometricAction: (() async -> Result<Void, DeviceSecurityAuthError>)?
    ) {
        self.titleText = title
        self.messageText = message
        self.leadingAction = leadingAction
        self.showsCloseButton = showsCloseButton
        self.verifyPasscode = verifyPasscode
        self.biometricAction = biometricAction
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
    }

    override func configureHierarchy() {
        view.addSubview(closeButton)
        view.addSubview(titleLabel)
        view.addSubview(messageLabel)
        view.addSubview(dotsStackView)
        view.addSubview(keypadStackView)

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

        let rows: [[KeypadItem]] = [
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

    override func configureLayout() {
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).inset(12)
            make.trailing.equalToSuperview().inset(20)
            make.size.equalTo(28)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(closeButton.snp.bottom).offset(24)
            make.horizontalEdges.equalToSuperview().inset(24)
        }

        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.horizontalEdges.equalToSuperview().inset(28)
        }

        dotsStackView.snp.makeConstraints { make in
            make.top.equalTo(messageLabel.snp.bottom).offset(32)
            make.centerX.equalToSuperview()
        }

        keypadStackView.snp.makeConstraints { make in
            make.top.equalTo(dotsStackView.snp.bottom).offset(40)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(360)
        }
    }

    override func configureView() {
        view.backgroundColor = GrayStyle.gray100.color
        titleLabel.text = titleText
        messageLabel.text = messageText
        closeButton.isHidden = !showsCloseButton
        updateDots()
    }

    override func configureBind() {
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard leadingAction == .biometric, !hasAttemptedBiometric else { return }
        hasAttemptedBiometric = true
        attemptBiometricAuthentication()
    }

    private func makeButton(for item: KeypadItem) -> UIView {
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

            button.addAction(UIAction(handler: { [weak self] _ in
                self?.handleTap(item)
            }), for: .touchUpInside)
            return button
        }
    }

    private func handleTap(_ item: KeypadItem) {
        switch item {
        case .digit(let number):
            guard enteredPasscode.count < 4 else { return }
            enteredPasscode.append(number)
            updateDots()
            if enteredPasscode.count == 4 {
                validatePasscode()
            }
        case .delete:
            guard !enteredPasscode.isEmpty else { return }
            enteredPasscode.removeLast()
            updateDots()
        case .biometric:
            attemptBiometricAuthentication()
        case .cancel:
            closeTapped()
        case .empty:
            break
        }
    }

    private func validatePasscode() {
        if verifyPasscode(enteredPasscode) {
            dismiss(animated: true) { [weak self] in
                self?.onSuccess?()
            }
            return
        }

        enteredPasscode = ""
        updateDots()
        showAlert(title: "암호 입력", message: "암호가 올바르지 않습니다.")
    }

    private func updateDots() {
        for (index, dot) in dotViews.enumerated() {
            let filled = index < enteredPasscode.count
            dot.backgroundColor = filled ? (Brand.brightTurquoise.color ?? .systemTeal) : .clear
            dot.layer.borderColor = (filled ? Brand.brightTurquoise.color : GrayStyle.gray60.color)?.cgColor
        }
    }

    private func attemptBiometricAuthentication() {
        guard let biometricAction else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            let result = await biometricAction()
            switch result {
            case .success:
                dismiss(animated: true) { [weak self] in
                    self?.onSuccess?()
                }
            case .failure(let error):
                guard error != .canceled else { return }
                showAlert(title: "생체 인증", message: error.errorDescription)
            }
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

    private func leadingKeypadItem() -> KeypadItem {
        switch leadingAction {
        case .biometric:
            return .biometric
        case .cancel:
            return .cancel
        case .empty:
            return .empty
        }
    }

    @objc private func closeTapped() {
        dismiss(animated: true) { [weak self] in
            self?.onCancel?()
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
