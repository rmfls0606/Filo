//
//  InsetTextField.swift
//  Filo
//
//  Created by 이상민 on 12/17/25.
//

import UIKit

final class InsetTextField: UITextField {
    //MARK: - Properties
    var contentInsets: UIEdgeInsets = .zero
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configure()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configure(){
        attributedPlaceholder = NSAttributedString(
            string: placeholder ?? "",
            attributes: [.foregroundColor: Brand.deepTurquoise.color ?? .clear]
        )
        borderStyle = .roundedRect
        layer.borderWidth = 2.0
        layer.borderColor = Brand.deepTurquoise.color?.cgColor
        layer.cornerRadius = 12
        font = .Pretendard.body2
        contentInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textColor = GrayStyle.gray60.color
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: contentInsets)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: contentInsets)
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: contentInsets)
    }
}
