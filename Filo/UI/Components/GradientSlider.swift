//
//  GradientSlider.swift
//  Filo
//
//  Created by 이상민 on 01/04/26.
//

import UIKit
import RxSwift
import RxCocoa

final class GradientSlider: UISlider {
    private let backgroundLayer = CALayer()
    private let gradientLayer = CAGradientLayer()
    
    private let disposeBag = DisposeBag()
    
    var thumbInset: CGFloat = 4{
        didSet { setNeedsLayout() }
    }

    private var initialTouchX: CGFloat = 0
    private var initialValue: Float = 0
    
    private var thumDotImage: UIImage = {
        let size = CGSize(width: 4, height: 4)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            let rect = CGRect(origin: .zero, size: size)
            let path = UIBezierPath(ovalIn: rect)
            Brand.blackTurquoise.color?.setFill()
            path.fill()
        }.withRenderingMode(.alwaysOriginal)
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
       
        configureView()
        configureBind()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let trackRect = self.trackRect(forBounds: bounds)
        backgroundLayer.frame = trackRect
        backgroundLayer.cornerRadius = trackRect.height / 2
        updateProgressMask()
    }
    
    override var alignmentRectInsets: UIEdgeInsets {
        .zero
    }

    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        return bounds
    }

    override func thumbRect(forBounds bounds: CGRect, trackRect: CGRect, value: Float) -> CGRect {
        let inset = max(0, min(thumbInset, trackRect.width / 2))
        let rect = super.thumbRect(forBounds: bounds, trackRect: trackRect, value: value)
        let thumbWidth = rect.width
        let available = max(1, trackRect.width - (thumbWidth + (inset * 2)))
        let range = maximumValue - minimumValue
        let ratio = range > 0 ? CGFloat((value - minimumValue) / range) : 0
        let clamped = max(0, min(1, ratio))
        let x = trackRect.minX + inset + (clamped * available)
        return CGRect(x: x, y: rect.minY, width: rect.width, height: rect.height)
    }

    override func setValue(_ value: Float, animated: Bool) {
        super.setValue(value, animated: animated)
        updateProgressMask()
    }

    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let point = touch.location(in: self)
        let trackRect = self.trackRect(forBounds: bounds)
        let trackWidth = max(trackRect.width, 1)
        let deltaX = point.x - initialTouchX
        let range = maximumValue - minimumValue
        let deltaValue = Float(deltaX / trackWidth) * range
        let rawValue = initialValue + deltaValue
        let step: Float
        if range >= 100 {
            step = 1.0
        } else {
            step = 0.1
        }
        let snappedValue = (rawValue / step).rounded() * step
        let newValue = min(maximumValue, max(minimumValue, snappedValue))
        if newValue != value {
            super.setValue(newValue, animated: false)
            sendActions(for: .valueChanged)
            updateProgressMask()
        }
        return true
    }

    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let point = touch.location(in: self)
        let hitRect = thumbHitRect()
        
        guard hitRect.contains(point) else {
            return false
        }

        initialTouchX = point.x
        initialValue = value
        return true
    }
    
    private func setupGradientLayer() {
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        gradientLayer.colors = [
            UIColor(red: 0.96, green: 0.13, blue: 0.62, alpha: 1.0).cgColor,
            UIColor(red: 0.17, green: 0.85, blue: 0.55, alpha: 1.0).cgColor
        ]
        backgroundLayer.backgroundColor = Brand.blackTurquoise.color?.cgColor
        layer.insertSublayer(backgroundLayer, at: 0)
        layer.insertSublayer(gradientLayer, at: 1)

        let clearTrack = UIImage()
        setMinimumTrackImage(clearTrack, for: .normal)
        setMaximumTrackImage(clearTrack, for: .normal)
    }

    private func configureView(){
        minimumValue = 0.0
        maximumValue = 1.0
        setupGradientLayer()
        setThumbImage(thumDotImage, for: .normal)
        setThumbImage(thumDotImage, for: .highlighted)
    }

    private func thumbHitRect() -> CGRect {
        let trackRect = self.trackRect(forBounds: bounds)
        let hitInsetX = max(0, min(thumbInset, trackRect.width / 2))
        let thumbRect = self.thumbRect(forBounds: bounds, trackRect: trackRect, value: value)
        let minY = min(trackRect.minY, thumbRect.minY)
        let maxY = max(trackRect.maxY, thumbRect.maxY)
        return CGRect(
            x: thumbRect.minX - hitInsetX,
            y: minY,
            width: thumbRect.width + (hitInsetX * 2),
            height: maxY - minY
        )
    }

    private func configureBind(){
        rx.controlEvent(.valueChanged)
            .subscribe(onNext: { [weak self] in
                self?.updateProgressMask()
            })
            .disposed(by: disposeBag)
    }
    
    private func updateProgressMask() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let trackRect = self.trackRect(forBounds: bounds)
        let thumbRect = self.thumbRect(forBounds: bounds, trackRect: trackRect, value: value)
        let width = (thumbRect.maxX - trackRect.minX) + thumbInset
        let clampedWidth = max(0, min(trackRect.width, width))
        gradientLayer.frame = CGRect(
            x: trackRect.minX,
            y: trackRect.minY,
            width: clampedWidth,
            height: trackRect.height
        )
        gradientLayer.cornerRadius = trackRect.height / 2
        CATransaction.commit()
    }
}
