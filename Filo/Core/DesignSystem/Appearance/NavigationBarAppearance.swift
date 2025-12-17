//
//  NavigationBarAppearance.swift
//  Filo
//
//  Created by 이상민 on 12/18/25.
//

import UIKit

enum NavigationBarAppearance{
    static func configure(){
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        
        appearance.titleTextAttributes = [
            .font: UIFont.Mulggeol.body1,
            .foregroundColor: GrayStyle.gray60.color
        ]
        
        let navigationBar = UINavigationBar.appearance()
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
    }
}
