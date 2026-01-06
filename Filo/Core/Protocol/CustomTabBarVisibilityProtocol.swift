//
//  CustomTabBarVisibilityProtocol.swift
//  Filo
//
//  Created by 이상민 on 1/7/26.
//

import UIKit

protocol CustomTabBarVisibilityProtocol{
    var prefersCustomTabBarHidden: Bool { get }
}

extension CustomTabBarVisibilityProtocol where Self: UIViewController{
    var prefersCustomTabBarHidden: Bool { false }

}
