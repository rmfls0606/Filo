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
            }
            .disposed(by: disposeBag)
    }
    
    private func switchToMain() {
        guard let scene = view.window?.windowScene,
              let delegate = scene.delegate as? SceneDelegate else { return }
        delegate.setRootViewController(MainTabBarController())
    }
}
