//
//  TabBarItem.swift
//  Filo
//
//  Created by 이상민 on 12/16/25.
//

import Foundation

enum TabBarItem: Int, CaseIterable{
    case home = 0
    case feed = 1
    case filter = 2
    case search = 3
    case profile = 4
    
    var iconName: String{
        return String(describing: self) + "_Empty"
    }
    
    var selectedIconName: String{
        return String(describing: self) + "_Fill"
    }
}
