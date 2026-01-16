//
//  GradientSlider.swift
//  Filo
//
//  Created by 이상민 on 01/04/26.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class FilterSliderView: BaseView {
    //MARK: - Properties
    private var valueLabelCenterXConstraint: Constraint?
    private let disposeBag = DisposeBag()
    
    var valueChanged: ControlProperty<Float> {
        slider.rx.value
    }
    
    var editingEnded: ControlEvent<Void> {
        slider.rx.controlEvent([.touchUpInside, .touchUpOutside, .touchCancel])
    }
    
    //MARK: - UI
    private let slider = GradientSlider()
    private let valueLabelBox: UIView = {
        let view = UIView()
        view.backgroundColor = Brand.blackTurquoise.color
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        return view
    }()
    
    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.body2
        label.textColor = GrayStyle.gray75.color
        label.textAlignment = .center
        return label
    }()

    override func layoutSubviews() {
        super.layoutSubviews()
        updateValueLabel(value: slider.value)
    }

    func configureValue(value: Float) {
        slider.setValue(value, animated: false)
        updateValueLabel(value: value)
    }
    
    override func configureHierarchy() {
        addSubview(valueLabelBox)
        valueLabelBox.addSubview(valueLabel)
        
        addSubview(slider)
    }

    override func configureLayout() {
        valueLabelBox.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalTo(slider.snp.top).offset(-8)
            valueLabelCenterXConstraint = make.centerX.equalTo(slider.snp.leading).constraint
        }
        
        valueLabel.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview().inset(4)
            make.horizontalEdges.equalToSuperview().inset(12)
        }
        
        slider.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(12)
            make.bottom.equalToSuperview()
        }
    }

    override func configureBind() {
        slider.rx.controlEvent(.valueChanged)
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                owner.updateValueLabel(value: owner.slider.value)
            })
            .disposed(by: disposeBag)
    }

    private func updateValueLabel(value: Float) {
        valueLabel.text = String(format: "%.1f", value)
        let trackRect = slider.trackRect(forBounds: slider.bounds)
        let thumbRect = slider.thumbRect(forBounds: slider.bounds, trackRect: trackRect, value: value)
        valueLabelCenterXConstraint?.update(offset: thumbRect.midX)
    }
}
