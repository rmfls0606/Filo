//
//  LikeButton.swift
//  Filo
//
//  Created by 이상민 on 1/25/26.
//

import UIKit

final class LikeButton: UIButton {
    var config = UIButton.Configuration.plain()
    var imageConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
    var selectedColor: UIColor?
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configure(){
        config.contentInsets = .zero
        config.preferredSymbolConfigurationForImage = imageConfig
        config.baseForegroundColor = .clear
        config.baseBackgroundColor = .clear
        config.image = UIImage(named: "like_Empty")
        configuration = config
        configurationUpdateHandler = {[weak self] btn in
            var config = btn.configuration
            if btn.isSelected{
                config?.image = UIImage(named: "like_Fill")
                config?.baseForegroundColor = self?.selectedColor ?? GrayStyle.gray30.color
            }else{
                config?.image = UIImage(named: "like_Empty")
                config?.baseForegroundColor = GrayStyle.gray60.color
            }
            btn.configuration = config
        }
    }
}
