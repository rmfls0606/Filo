//
//  DarkGradientView.swift
//  Filo
//
//  Created by 이상민 on 1/22/26.
//

import UIKit

final class DarkGradientView: BaseView {
    private let gradientLayer = CAGradientLayer()
    
    private let baseColor = UIColor(red: 11/255, green: 11/255, blue: 11/255, alpha: 1)
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        gradientLayer.frame = bounds
    }
    
    override func configureHierarchy() {
        layer.addSublayer(gradientLayer)
    }
    
    override func configureView() {
        backgroundColor = .clear
        
        gradientLayer.colors = [
            baseColor.withAlphaComponent(0.0).cgColor,
            baseColor.withAlphaComponent(0.4).cgColor,
            baseColor.withAlphaComponent(1.0).cgColor
        ]
        
        gradientLayer.locations = [0.0, 0.4, 0.8]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint   = CGPoint(x: 0.5, y: 1.0)
    }
}
