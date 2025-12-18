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
    
    private let tapButton: UIButton = {
        let button = UIButton()
        return button
    }()
    
    override func configureHierarchy() {
        addSubview(containerView)
        containerView.addSubview(plusImageView)
        containerView.addSubview(imageView)
        containerView.addSubview(tapButton)
    }
    
    override func configureLayout() {
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            emptyHeightConstraint = make.height.equalTo(100).constraint
            squareHeightConstraint = make.height.equalTo(containerView.snp.width).constraint
            squareHeightConstraint?.deactivate()
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
