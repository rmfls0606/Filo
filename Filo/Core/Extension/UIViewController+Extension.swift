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
    
    func showAlert(title: String, message: String?){
        let alert = UIAlertController(title: title, message: message ?? "알 수 없는 오류가 발생했습니다.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}
