//
//  FilterImageRegisterView.swift
//  Filo
//
//  Created by 이상민 on 12/18/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

enum FilterImageState{
    case empty
    case filled(UIImage)
}

final class FilterImageRegisterView: BaseView {
    //MARK: - Properties
    private let dispostBag = DisposeBag()
    private let stateRelay = BehaviorRelay<FilterImageState>(value: .empty)
    private var emptyHeightConstraint: Constraint?
    private var squareHeightConstraint: Constraint?
    
    var tap: ControlEvent<Void>{
        tapButton.rx.tap
    }
    
    var state: Observable<FilterImageState>{
        stateRelay.asObservable()
    }
    
    //MARK: - UI
    private let mainStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        return stack
    }()
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = Brand.blackTurquoise.color
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        return view
    }()
    
    //Empty
    private let plusImageView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(named: "add")
        view.contentMode = .scaleAspectFit
        view.tintColor = GrayStyle.gray75.color
        return view
    }()
    
    //Filled
    private let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.isHidden = true
        return view
    }()
    
    private let metadataContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        view.layer.borderWidth = 2.0
        view.layer.borderColor = Brand.blackTurquoise.color?.cgColor
        view.backgroundColor = Brand.blackTurquoise.color
        return view
    }()
    
    private let metadataHeaderView: UIView = {
        let view = UIView()
        view.backgroundColor = .gray100
        return view
    }()
    
    private let metadataHeaderStack: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.alignment = .center
        view.distribution = .fill
        view.spacing = 8
        return view
    }()

    private let deviceLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.caption1
        label.textColor = Brand.deepTurquoise.color
        label.text = "Apple iPhone 16 pro"
        return label
    }()
    
    private let exifLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.caption1
        label.textColor = Brand.deepTurquoise.color
        label.text = "EXIF"
        return label
    }()
    
    private let metadataContentView: UIView = {
        let view = UIView()
        view.backgroundColor = Brand.blackTurquoise.color
        return view
    }()
    
    private let mapImageViewContainer: UIView = {
        let view = UIView()
        return view
    }()
    
    private let mapImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.layer.borderWidth = 2.0
        imageView.layer.borderColor = Brand.deepTurquoise.color?.cgColor
        imageView.backgroundColor = Brand.blackTurquoise.color
        return imageView
    }()
    
    private let mapPlaceholderStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 2
        return stack
    }()
    
    private let mapPlaceholderImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "noLocation")
        imageView.tintColor = Brand.deepTurquoise.color
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let mapPlaceholderLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.caption2
        label.textColor = Brand.deepTurquoise.color
        label.text = "No Location"
        return label
    }()
    
    private let metadataContentStack: UIStackView = {
         let view = UIStackView()
        view.axis = .horizontal
        view.spacing = 16
        view.alignment = .center
        return view
    }()
    
    private let metadataInfoTextStack: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 8
        view.alignment = .leading
        view.distribution = .fill
        return view
    }()
    
    private let cameraLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.caption1
        label.textColor = GrayStyle.gray75.color
        label.numberOfLines = 0
        label.text = "와이드 카메라 - 26mm f1.5 ISO 400"
        return label
    }()
    
    private let detailLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.caption1
        label.textColor = GrayStyle.gray75.color
        label.numberOfLines = 0
        return label
    }()
    
    private let locationLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.caption1
        label.textColor = GrayStyle.gray75.color
        label.numberOfLines = 2
        label.text = "12MP 3024 x 4032 2.2MB"
        return label
    }()
    
    private let tapButton: UIButton = {
        let button = UIButton()
        return button
    }()
    
    override func configureHierarchy() {
        addSubview(mainStack)
        
        mainStack.addArrangedSubview(containerView)
        mainStack.addArrangedSubview(metadataContainer)
        
        containerView.addSubview(plusImageView)
        containerView.addSubview(imageView)
        containerView.addSubview(tapButton)
        
        metadataContainer.addSubview(metadataHeaderView)
        metadataHeaderView.addSubview(metadataHeaderStack)
        metadataHeaderStack.addArrangedSubview(deviceLabel)
        metadataHeaderStack.addArrangedSubview(exifLabel)
        
        metadataContainer.addSubview(metadataContentView)
        metadataContentView.addSubview(metadataContentStack)
        
        metadataContentStack.addArrangedSubview(mapImageViewContainer)
        metadataContentStack.addArrangedSubview(metadataInfoTextStack)
        
        mapImageViewContainer.addSubview(mapImageView)
        mapImageViewContainer.addSubview(mapPlaceholderStack)
        mapPlaceholderStack.addArrangedSubview(mapPlaceholderImageView)
        mapPlaceholderStack.addArrangedSubview(mapPlaceholderLabel)
        
        metadataInfoTextStack.addArrangedSubview(cameraLabel)
        metadataInfoTextStack.addArrangedSubview(detailLabel)
        metadataInfoTextStack.addArrangedSubview(locationLabel)
    }
    
    override func configureLayout() {
        mainStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        containerView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            emptyHeightConstraint = make.height.equalTo(100).constraint
            squareHeightConstraint = make.height.equalTo(containerView.snp.width).constraint
            squareHeightConstraint?.deactivate()
        }
        
        metadataContainer.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
        }
        
        metadataHeaderView.snp.makeConstraints { make in
            make.top.horizontalEdges.equalToSuperview()
            make.bottom.equalTo(metadataContentView.snp.top)
        }
        
        metadataHeaderStack.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(12)
            make.verticalEdges.equalToSuperview().inset(8)
        }

        metadataContentView.snp.makeConstraints { make in
            make.top.equalTo(metadataHeaderView.snp.bottom)
            make.horizontalEdges.bottom.equalToSuperview()
        }
        
        metadataContentStack.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(8)
            make.verticalEdges.equalToSuperview().inset(12)
        }
        
        metadataInfoTextStack.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview()
        }
        
        mapImageViewContainer.snp.makeConstraints { make in
            make.leading.verticalEdges.equalToSuperview()
            make.size.equalTo(76)
        }
        
        mapImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        mapPlaceholderStack.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        plusImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        tapButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    override func configureBind() {
        stateRelay
            .subscribe { [weak self] state in
                self?.apply(state)
            }
            .disposed(by: dispostBag)
    }
    
    func setImage(_ image: UIImage){
        stateRelay.accept(.filled(image))
    }
    
    func reset(){
        stateRelay.accept(.empty)
    }
    
    private func apply(_ state: FilterImageState){
        switch state {
        case .empty:
            plusImageView.isHidden = false
            imageView.isHidden = true
            squareHeightConstraint?.deactivate()
            emptyHeightConstraint?.activate()
        case .filled(let image):
            imageView.image = image
            plusImageView.isHidden = true
            imageView.isHidden = false
            emptyHeightConstraint?.deactivate()
            squareHeightConstraint?.activate()
            
            containerView.layer.borderWidth = 2.0
            containerView.layer.borderColor = Brand.deepTurquoise.color?.cgColor
        }
    }
}
