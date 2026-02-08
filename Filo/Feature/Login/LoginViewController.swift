//
//  LoginViewController.swift
//  Filo
//
//  Created by 이상민 on 1/26/26.
//

import UIKit
import AuthenticationServices
import SnapKit
import RxSwift
import RxCocoa

final class LoginViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    private let viewModel = LoginViewModel()
    private let viewTapGesture = UITapGestureRecognizer()
    private let rememberEmailEnabledKey = "rememberEmailEnabled"
    private let rememberedEmailKey = "rememberedEmail"
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "FILO"
        label.font = .Mulggeol.title1
        label.textColor = GrayStyle.gray30.color
        label.textAlignment = .center
        return label
    }()
    
    private let emailField: InsetTextField = {
        let field = InsetTextField()
        field.placeholder = "이메일"
        field.keyboardType = .emailAddress
        field.autocapitalizationType = .none
        return field
    }()
    
    private let passwordField: InsetTextField = {
        let field = InsetTextField()
        field.placeholder = "비밀번호"
        field.isSecureTextEntry = true
        field.autocapitalizationType = .none
        return field
    }()
    
    private let rememberMeStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.spacing = 8
        view.alignment = .center
        return view
    }()
    
    private let rememberMeButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.baseBackgroundColor = .clear
        config.baseForegroundColor = GrayStyle.gray75.color
        let button = UIButton(configuration: config)
        button.configurationUpdateHandler = { button in
            var config = button.configuration
            let imageName = button.isSelected ? "checkmark.square" : "square"
            config?.image = UIImage(systemName: imageName)
            button.configuration = config
        }
        return button
    }()
    
    private let rememberMeLabel: UILabel = {
        let label = UILabel()
        label.text = "아이디 저장"
        label.font = .Pretendard.caption1
        label.textColor = GrayStyle.gray75.color
        return label
    }()
    
    private let loginButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = Brand.brightTurquoise.color
        config.baseForegroundColor = GrayStyle.gray45.color
        config.cornerStyle = .medium
        config.title = "로그인"
        let button = UIButton(configuration: config)
        return button
    }()
    
    private let signUpButton: UIButton = {
        var config = UIButton.Configuration.bordered()
        config.baseForegroundColor = Brand.brightTurquoise.color
        config.background.strokeColor = Brand.brightTurquoise.color
        config.background.strokeWidth = 1.5
        config.cornerStyle = .medium
        config.title = "회원가입"
        let button = UIButton(configuration: config)
        return button
    }()
    
    private let contentStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 12
        view.alignment = .fill
        return view
    }()
    
    override func configureHierarchy() {
        view.addSubview(contentStackView)
        contentStackView.addArrangedSubview(titleLabel)
        contentStackView.addArrangedSubview(emailField)
        contentStackView.addArrangedSubview(passwordField)
        contentStackView.addArrangedSubview(rememberMeStackView)
        rememberMeStackView.addArrangedSubview(rememberMeButton)
        rememberMeStackView.addArrangedSubview(rememberMeLabel)
        contentStackView.addArrangedSubview(loginButton)
        contentStackView.addArrangedSubview(signUpButton)
        
        view.addGestureRecognizer(viewTapGesture)
    }
    
    override func configureLayout() {
        contentStackView.snp.makeConstraints { make in
            make.centerY.equalTo(view.safeAreaLayoutGuide)
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        
        emailField.snp.makeConstraints { make in
            make.height.equalTo(48)
        }
        
        passwordField.snp.makeConstraints { make in
            make.height.equalTo(48)
        }
        
        rememberMeButton.snp.makeConstraints { make in
            make.size.equalTo(28)
        }
        
        rememberMeStackView.snp.makeConstraints { make in
            make.height.equalTo(28)
        }
        
        loginButton.snp.makeConstraints { make in
            make.height.equalTo(48)
        }
        
        signUpButton.snp.makeConstraints { make in
            make.height.equalTo(48)
        }
    }
    
    override func configureView() {
        view.backgroundColor = .black
        applyRememberedEmail()
        rememberMeButton.setNeedsUpdateConfiguration()
    }
    
    override func configureBind() {
        let input = LoginViewModel.Input(
            emailText: emailField.rx.text.orEmpty,
            passwordText: passwordField.rx.text.orEmpty,
            loginTapped: loginButton.rx.tap
        )
        
        let output = viewModel.transform(input: input)
        
        output.loginEnabled
            .drive(loginButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        output.loginSuccess
            .drive(with: self) { owner, _ in
                owner.persistRememberedEmailIfNeeded()
                owner.switchToMain()
            }
            .disposed(by: disposeBag)
        
        output.loginError
            .drive(with: self) { owner, message in
                owner.showAlert(title: "로그인 실패", message: message)
            }
            .disposed(by: disposeBag)
        
        viewTapGesture.rx.event
            .bind(with: self) { owner, _ in
                owner.view.endEditing(true)
            }
            .disposed(by: disposeBag)
        
        rememberMeButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.rememberMeButton.isSelected.toggle()
                owner.persistRememberToggleState()
            }
            .disposed(by: disposeBag)
        
        signUpButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.moveToSignUp()
            }
            .disposed(by: disposeBag)
    }
    
    private func switchToMain() {
        guard let scene = view.window?.windowScene,
              let delegate = scene.delegate as? SceneDelegate else { return }
        delegate.setRootViewController(MainTabBarController())
    }
    
    private func moveToSignUp() {
        let vc = SignUpViewController()
        if let navigationController {
            navigationController.pushViewController(vc, animated: true)
        } else {
            let nav = UINavigationController(rootViewController: vc)
            present(nav, animated: true)
        }
    }
    
    private func applyRememberedEmail() {
        let defaults = UserDefaults.standard
        let isEnabled = defaults.bool(forKey: rememberEmailEnabledKey)
        rememberMeButton.isSelected = isEnabled
        if isEnabled {
            emailField.text = defaults.string(forKey: rememberedEmailKey) ?? ""
        } else {
            emailField.text = ""
        }
    }
    
    private func persistRememberToggleState() {
        let defaults = UserDefaults.standard
        defaults.set(rememberMeButton.isSelected, forKey: rememberEmailEnabledKey)
        if !rememberMeButton.isSelected {
            defaults.removeObject(forKey: rememberedEmailKey)
        }
    }
    
    private func persistRememberedEmailIfNeeded() {
        let defaults = UserDefaults.standard
        defaults.set(rememberMeButton.isSelected, forKey: rememberEmailEnabledKey)
        if rememberMeButton.isSelected {
            let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            defaults.set(email, forKey: rememberedEmailKey)
        } else {
            defaults.removeObject(forKey: rememberedEmailKey)
        }
    }
}

final class SignUpViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    private let viewTapGesture = UITapGestureRecognizer()
    
    private let scrollView: UIScrollView = {
        let view = UIScrollView()
        view.keyboardDismissMode = .interactive
        return view
    }()
    
    private let contentView = UIView()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "회원가입"
        label.font = .Mulggeol.title1
        label.textColor = GrayStyle.gray30.color
        label.textAlignment = .center
        return label
    }()
    
    private let emailField = SignUpViewController.makeField(placeholder: "이메일")
    private let nickField = SignUpViewController.makeField(placeholder: "닉네임")
    private let nameField = SignUpViewController.makeField(placeholder: "이름")
    private let introductionField = SignUpViewController.makeField(placeholder: "소개")
    private let phoneField: InsetTextField = {
        let field = InsetTextField()
        field.placeholder = "전화번호"
        field.keyboardType = .phonePad
        field.autocapitalizationType = .none
        return field
    }()
    private let hashTagsField = SignUpViewController.makeField(placeholder: "해시태그(예: #감성 #필름)")
    private let passwordField: InsetTextField = {
        let field = InsetTextField()
        field.placeholder = "비밀번호"
        field.autocapitalizationType = .none
        field.isSecureTextEntry = true
        return field
    }()
    
    private let signUpButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = Brand.brightTurquoise.color
        config.baseForegroundColor = GrayStyle.gray45.color
        config.cornerStyle = .medium
        config.title = "회원가입"
        let button = UIButton(configuration: config)
        return button
    }()
    
    private let contentStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 12
        return view
    }()
    
    override func configureHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(contentStackView)
        contentStackView.addArrangedSubview(titleLabel)
        contentStackView.addArrangedSubview(emailField)
        contentStackView.addArrangedSubview(nickField)
        contentStackView.addArrangedSubview(nameField)
        contentStackView.addArrangedSubview(introductionField)
        contentStackView.addArrangedSubview(phoneField)
        contentStackView.addArrangedSubview(hashTagsField)
        contentStackView.addArrangedSubview(passwordField)
        contentStackView.addArrangedSubview(signUpButton)
        view.addGestureRecognizer(viewTapGesture)
    }
    
    override func configureLayout() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }
        
        contentStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(24)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(24)
        }
        
        emailField.snp.makeConstraints { make in
            make.height.equalTo(48)
        }
        
        nickField.snp.makeConstraints { make in
            make.height.equalTo(48)
        }
        
        nameField.snp.makeConstraints { make in
            make.height.equalTo(48)
        }
        
        introductionField.snp.makeConstraints { make in
            make.height.equalTo(48)
        }
        
        phoneField.snp.makeConstraints { make in
            make.height.equalTo(48)
        }
        
        hashTagsField.snp.makeConstraints { make in
            make.height.equalTo(48)
        }
        
        passwordField.snp.makeConstraints { make in
            make.height.equalTo(48)
        }
        
        signUpButton.snp.makeConstraints { make in
            make.height.equalTo(48)
        }
    }
    
    override func configureView() {
        view.backgroundColor = GrayStyle.gray100.color
        navigationItem.title = "회원가입"
        if presentingViewController != nil {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .close,
                target: self,
                action: #selector(closeTapped)
            )
        }
    }
    
    override func configureBind() {
        signUpButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.requestSignUp()
            }
            .disposed(by: disposeBag)
        
        viewTapGesture.rx.event
            .bind(with: self) { owner, _ in
                owner.view.endEditing(true)
            }
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx.notification(UIResponder.keyboardWillChangeFrameNotification)
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, notification in
                owner.updateKeyboardInset(notification: notification)
            }
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx.notification(UIResponder.keyboardWillHideNotification)
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, _ in
                owner.scrollView.contentInset.bottom = 0
                owner.scrollView.verticalScrollIndicatorInsets.bottom = 0
            }
            .disposed(by: disposeBag)
        
        Observable.merge(
            emailField.rx.controlEvent(.editingDidBegin).asObservable().map { [weak self] in self?.emailField },
            nickField.rx.controlEvent(.editingDidBegin).asObservable().map { [weak self] in self?.nickField },
            nameField.rx.controlEvent(.editingDidBegin).asObservable().map { [weak self] in self?.nameField },
            introductionField.rx.controlEvent(.editingDidBegin).asObservable().map { [weak self] in self?.introductionField },
            phoneField.rx.controlEvent(.editingDidBegin).asObservable().map { [weak self] in self?.phoneField },
            hashTagsField.rx.controlEvent(.editingDidBegin).asObservable().map { [weak self] in self?.hashTagsField },
            passwordField.rx.controlEvent(.editingDidBegin).asObservable().map { [weak self] in self?.passwordField }
        )
        .compactMap { $0 }
        .bind(with: self) { owner, field in
            owner.scrollToField(field)
        }
        .disposed(by: disposeBag)
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    private func requestSignUp() {
        let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let nick = nickField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let introduction = introductionField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let phoneNum = phoneField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let hashTagsText = hashTagsField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = passwordField.text ?? ""
        
        guard validateEmail(email) else {
            showAlert(title: "회원가입 실패", message: "이메일은 유효한 형식이어야 합니다 (예: user@example.com)")
            return
        }
        
        guard validateNick(nick) else {
            showAlert(title: "회원가입 실패", message: ".,?*-@+^${}()|[]\\\\ 문자는 nick에 포함할 수 없습니다.")
            return
        }
        
        guard validatePassword(password) else {
            showAlert(title: "회원가입 실패", message: "비밀번호는 최소 8자 이상이며, 영문자/숫자/특수문자(@$!%*#?&)를 각각 1개 이상 포함해야 합니다.")
            return
        }
        
        guard !name.isEmpty else {
            showAlert(title: "회원가입 실패", message: "이름을 입력해주세요.")
            return
        }
        
        let hashTags = parseHashTags(hashTagsText)
        
        Task { [weak self] in
            guard let self else { return }
            do {
                let _: ServerErrorDTO = try await NetworkManager.shared.request(
                    UserRouter.email(email: email)
                )
                
                let deviceToken = UserDefaults.standard.string(forKey: "fcmToken") ?? ""
                let _: JoinResponseDTO = try await NetworkManager.shared.request(
                    UserRouter.join(
                        email: email,
                        password: password,
                        nick: nick,
                        name: name,
                        introduction: introduction,
                        phoneNum: phoneNum,
                        hashTags: hashTags,
                        deviceToken: deviceToken
                    )
                )
                await MainActor.run {
                    self.showAlert(title: "완료", message: "회원가입이 완료되었습니다.") { [weak self] in
                        guard let self else { return }
                        if let nav = self.navigationController {
                            nav.popViewController(animated: true)
                        } else {
                            self.dismiss(animated: true)
                        }
                    }
                }
            } catch let error as NetworkError {
                await MainActor.run {
                    self.showAlert(title: "회원가입 실패", message: error.errorDescription)
                }
            } catch {
                await MainActor.run {
                    self.showAlert(title: "회원가입 실패", message: error.localizedDescription)
                }
            }
        }
    }
    
    private func validateEmail(_ email: String) -> Bool {
        let pattern = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: email)
    }
    
    private func validateNick(_ nick: String) -> Bool {
        guard !nick.isEmpty else { return false }
        let invalidPattern = "[\\.,\\?\\*\\-@\\+\\^\\$\\{\\}\\(\\)\\|\\[\\]\\\\]"
        let hasInvalid = NSPredicate(format: "SELF MATCHES %@", ".*\(invalidPattern).*").evaluate(with: nick)
        return !hasInvalid
    }
    
    private func validatePassword(_ password: String) -> Bool {
        let pattern = "^(?=.*[A-Za-z])(?=.*\\d)(?=.*[@$!%*#?&]).{8,}$"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: password)
    }
    
    private func parseHashTags(_ text: String) -> [String] {
        text
            .split(separator: " ")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .map { $0.replacingOccurrences(of: "#", with: "") }
            .filter { !$0.isEmpty }
    }
    
    private static func makeField(placeholder: String) -> InsetTextField {
        let field = InsetTextField()
        field.placeholder = placeholder
        field.autocapitalizationType = .none
        return field
    }
    
    private func updateKeyboardInset(notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let frame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        else { return }
        
        let keyboardFrameInView = view.convert(frame, from: nil)
        let overlap = view.bounds.intersection(keyboardFrameInView).height
        let bottomInset = max(0, overlap - view.safeAreaInsets.bottom) + 16
        scrollView.contentInset.bottom = bottomInset
        scrollView.verticalScrollIndicatorInsets.bottom = bottomInset
    }
    
    private func scrollToField(_ field: UIView) {
        let frame = field.convert(field.bounds, to: scrollView)
        scrollView.scrollRectToVisible(frame.insetBy(dx: 0, dy: -20), animated: true)
    }
}
