//
//  UIButton+Extension.swift
//  Filo
//
//  Created by 이상민 on 12/25/25.
//

import UIKit

extension UIButton.Configuration{
    mutating func makeFilterResizeImageConfigurationFill(imageName: String){
        image = UIImage(named: imageName)?
            .resized(to: CGSize(width: 24, height: 24))
            .withRenderingMode(.alwaysTemplate)
        
        baseBackgroundColor = GrayStyle.gray75.color?.withAlphaComponent(0.5)
        
        contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
        
        background.cornerRadius = 12
        background.strokeWidth = 1.0
        background.strokeColor = GrayStyle.gray75.color?.withAlphaComponent(0.5)
    }
}
