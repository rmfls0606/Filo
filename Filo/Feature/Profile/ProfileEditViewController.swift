//
//  ProfileEditViewController.swift
//  Filo
//
//  Created by 이상민 on 2/8/26.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import PhotosUI
import UniformTypeIdentifiers
import Toast

final class ProfileEditViewController: BaseViewController {
    private let viewModel: ProfileEditViewModel
    private let disposeBag = DisposeBag()
    var onUpdated: (() -> Void)?
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let profileImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.layer.cornerRadius = 48
        view.layer.borderWidth = 1.0
        view.layer.borderColor = GrayStyle.gray75.color?.withAlphaComponent(0.5).cgColor
        view.clipsToBounds = true
        view.backgroundColor = GrayStyle.gray90.color
        return view
    }()
    
    private let imageEditButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = Brand.deepTurquoise.color
        config.baseForegroundColor = GrayStyle.gray30.color
        config.cornerStyle = .capsule
        config.title = "이미지 변경"
        let button = UIButton(configuration: config)
        return button
    }()
    
    private let nickField = ProfileEditViewController.makeField(placeholder: "닉네임")
    private let nameField = ProfileEditViewController.makeField(placeholder: "이름")
    private let phoneField: InsetTextField = {
        let field = ProfileEditViewController.makeField(placeholder: "전화번호")
        field.keyboardType = .phonePad
        return field
    }()
    
    private let introTextView: UITextView = {
        let view = UITextView()
        view.font = .Pretendard.body2
        view.textColor = GrayStyle.gray30.color
        view.backgroundColor = GrayStyle.gray100.color
        view.layer.cornerRadius = 10
        view.layer.borderWidth = 2.0
        view.layer.borderColor = Brand.deepTurquoise.color?.cgColor
        view.textContainerInset = .init(top: 12, left: 8, bottom: 12, right: 8)
        return view
    }()
    
    private let introPlaceholderLabel: UILabel = {
        let label = UILabel()
        label.text = "소개"
        label.font = .Pretendard.body2
        label.textColor = GrayStyle.gray75.color
        return label
    }()
    
    private let hashTagsField = ProfileEditViewController.makeField(placeholder: "#태그, 태그2")
    
    private let saveButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = Brand.deepTurquoise.color
        config.baseForegroundColor = GrayStyle.gray30.color
        config.cornerStyle = .capsule
        config.title = "저장"
        let button = UIButton(configuration: config)
        return button
    }()
    
    private let imageDataRelay = BehaviorRelay<Data?>(value: nil)
    
    init(viewModel: ProfileEditViewModel = ProfileEditViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    
    override func configureView() {
        view.backgroundColor = GrayStyle.gray100.color
        navigationItem.title = "프로필 편집"
    }
    
    override func configureHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(profileImageView)
        contentView.addSubview(imageEditButton)
        contentView.addSubview(nickField)
        contentView.addSubview(nameField)
        contentView.addSubview(phoneField)
        contentView.addSubview(introTextView)
        introTextView.addSubview(introPlaceholderLabel)
        contentView.addSubview(hashTagsField)
        contentView.addSubview(saveButton)
    }
    
    override func configureLayout() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView.frameLayoutGuide)
        }
        
        profileImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(24)
            make.centerX.equalToSuperview()
            make.size.equalTo(96)
        }
        
        imageEditButton.snp.makeConstraints { make in
            make.top.equalTo(profileImageView.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
            make.height.equalTo(32)
        }
        
        nickField.snp.makeConstraints { make in
            make.top.equalTo(imageEditButton.snp.bottom).offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(44)
        }
        
        nameField.snp.makeConstraints { make in
            make.top.equalTo(nickField.snp.bottom).offset(12)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(44)
        }
        
        phoneField.snp.makeConstraints { make in
            make.top.equalTo(nameField.snp.bottom).offset(12)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(44)
        }
        
        introTextView.snp.makeConstraints { make in
            make.top.equalTo(phoneField.snp.bottom).offset(12)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(120)
        }
        
        introPlaceholderLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.top.equalToSuperview().inset(12)
        }
        
        hashTagsField.snp.makeConstraints { make in
            make.top.equalTo(introTextView.snp.bottom).offset(12)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(44)
        }
        
        saveButton.snp.makeConstraints { make in
            make.top.equalTo(hashTagsField.snp.bottom).offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(44)
            make.bottom.equalToSuperview().inset(24)
        }
    }
    
    override func configureBind() {
        let tapGesture = UITapGestureRecognizer()
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        tapGesture.rx.event
            .bind(with: self) { owner, _ in
                owner.view.endEditing(true)
            }
            .disposed(by: disposeBag)

        let input = ProfileEditViewModel.Input(
            viewWillAppear: rx.methodInvoked(#selector(UIViewController.viewWillAppear(_:))).map { _ in },
            imageData: imageDataRelay.asObservable(),
            nickText: nickField.rx.text.orEmpty.asObservable(),
            nameText: nameField.rx.text.orEmpty.asObservable(),
            introText: introTextView.rx.text.orEmpty.asObservable(),
            phoneText: phoneField.rx.text.orEmpty.asObservable(),
            hashTagsText: hashTagsField.rx.text.orEmpty.asObservable(),
            saveTap: saveButton.rx.tap.asObservable()
        )
        
        let output = viewModel.transform(input: input)
        
        output.profileItem
            .drive(with: self) { owner, item in
                guard let item else { return }
                owner.nickField.text = item.nick
                owner.nameField.text = item.name
                owner.phoneField.text = item.phoneNum
                owner.introTextView.text = item.introduction ?? ""
                owner.introPlaceholderLabel.isHidden = !(item.introduction ?? "").isEmpty
                let hashText = item.hashTags.map { "#\($0)" }.joined(separator: " ")
                owner.hashTagsField.text = hashText
                if let profile = item.profileImage {
                    owner.profileImageView.setKFImage(urlString: profile, targetSize: owner.profileImageView.bounds.size)
                } else {
                    owner.profileImageView.image = nil
                }
            }
            .disposed(by: disposeBag)
        
        output.saveEnabled
            .drive(with: self) { owner, enabled in
                owner.saveButton.alpha = enabled ? 1.0 : 0.4
            }
            .disposed(by: disposeBag)
        
        output.saveSuccess
            .emit(with: self) { owner, _ in
                owner.view.makeToast("프로필이 수정되었습니다")
                owner.onUpdated?()
                owner.navigationController?.popViewController(animated: true)
            }
            .disposed(by: disposeBag)
        
        output.networkError
            .emit(with: self) { owner, error in
                owner.showAlert(title: "오류", message: error.errorDescription)
            }
            .disposed(by: disposeBag)
        
        imageEditButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.presentImagePicker()
            }
            .disposed(by: disposeBag)
        
        introTextView.rx.text.orEmpty
            .map { !$0.isEmpty }
            .bind(with: self) { owner, hasText in
                owner.introPlaceholderLabel.isHidden = hasText
            }
            .disposed(by: disposeBag)
    }
}

private extension ProfileEditViewController {
    static func makeField(placeholder: String) -> InsetTextField {
        let field = InsetTextField()
        field.placeholder = placeholder
        field.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: Brand.deepTurquoise.color ?? .clear]
        )
        return field
    }

    func presentImagePicker() {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
}

extension ProfileEditViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let result = results.first else { return }
        let provider = result.itemProvider
        guard provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) else { return }
        provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { [weak self] data, _ in
            guard let self, let data else { return }
            let image = UIImage(data: data)
            let jpegData = image?.jpegData(compressionQuality: 0.8) ?? data
            DispatchQueue.main.async {
                self.profileImageView.image = image
                self.imageDataRelay.accept(jpegData)
            }
        }
    }
}
