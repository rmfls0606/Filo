//
//  UIViewController+Extension.swift
//  Filo
//
//  Created by 이상민 on 1/7/26.
//

import UIKit

extension UIViewController {
    func setMainCustomTabBarHidden(_ hidden: Bool, animated: Bool = true) {
        (tabBarController as? MainTabBarController)?
            .setCustomTabBarHidden(hidden, animated: animated)
    }
}
