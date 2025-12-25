//
//  UIImage+Extension.swift
//  Filo
//
//  Created by 이상민 on 12/25/25.
//

import UIKit

extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
