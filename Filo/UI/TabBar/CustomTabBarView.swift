//
//  CustomTabBarView.swift
//  Filo
//
//  Created by 이상민 on 12/16/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class CustomTabBarView: BaseView{
    static let height: CGFloat = 64
    //MARK: - Properties
    private let selectedItemRelay = BehaviorRelay<TabBarItem>(value: .home)
    private let disposeBag = DisposeBag()
    private var indicatorCenterXConstraint: Constraint?
    
    var selectedItem: Observable<TabBarItem>{
        selectedItemRelay.asObservable()
    }
    
    //MARK: - View
    private let stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.alignment = .center
        view.distribution = .equalSpacing
        return view
    }()
    
    private let blurView: UIVisualEffectView = {
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        blurView.layer.cornerRadius = 32
        blurView.clipsToBounds = true
        blurView.backgroundColor = GrayStyle.gray75.color?.withAlphaComponent(0.5)
        blurView.layer.borderWidth = 1.0
        blurView.layer.borderColor = GrayStyle.gray75.color?.withAlphaComponent(0.5).cgColor
        return blurView
    }()
    
    private let indicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = GrayStyle.gray15.color
        view.layer.cornerRadius = 1
        return view
    }()
    
    private var buttons = [UIButton]()
    
    override func configureHierarchy() {
        addSubview(blurView)
        blurView.contentView.addSubview(stackView)
        blurView.contentView.addSubview(indicatorView)
        
        makeButtons()
        
        buttons.forEach { button in
            stackView.addArrangedSubview(button)
        }
    }
    
    override func configureLayout() {
        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        stackView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(32)
            make.verticalEdges.equalToSuperview()
        }
        
        indicatorView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(1)
            make.height.equalTo(5)
            make.width.equalTo(32)
            indicatorCenterXConstraint = make.centerX
                .equalTo(buttons[0])
                .constraint
        }
    }
    
    override func configureBind() {
        buttons.forEach { button in
            button.rx.tap
                .compactMap{ TabBarItem(rawValue: button.tag) }
                .bind(to: selectedItemRelay)
                .disposed(by: disposeBag)
        }
        
        selectedItemRelay
            .subscribe { [weak self] item in
                self?.updateSelection(item)
            }
            .disposed(by: disposeBag)
    }
    
    private func makeButtons(){
        buttons = TabBarItem.allCases.map { item in
            let button = UIButton(type: .system)
            button.setImage(UIImage(named: item.iconName), for: .normal)
            button.tintColor = .white.withAlphaComponent(0.4)
            button.tag = item.rawValue
            return button
        }
    }
    
    private func updateSelection(_ selectedItem: TabBarItem) {
        buttons.forEach { button in
            guard let item = TabBarItem(rawValue: button.tag) else { return }
            let isSelected = item == selectedItem
            
            let imageName = isSelected ? item.selectedIconName : item.iconName
            
            button.setImage(UIImage(named: imageName), for: .normal)
            
            button.tintColor = isSelected ? GrayStyle.gray15.color : GrayStyle.gray45.color
        }
        let selectedButton = buttons[selectedItem.rawValue]
        
        indicatorCenterXConstraint?.deactivate()
        
        indicatorView.snp.makeConstraints {
            indicatorCenterXConstraint = $0.centerX
                .equalTo(selectedButton)
                .constraint
        }
        
        UIView.animate(withDuration: 0.25,
                       delay: 0,
                       options: [.curveEaseOut]) {
            self.layoutIfNeeded()
        }
    }
}
