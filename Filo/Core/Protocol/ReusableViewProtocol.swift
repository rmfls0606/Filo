//
//  ReusableViewProtocol.swift
//  Filo
//
//  Created by 이상민 on 12/16/25.
//

import UIKit

protocol ReusableViewProtocol{
    static var identifier: String { get }
}

extension UICollectionViewCell: ReusableViewProtocol{
    static var identifier: String{
        return String(describing: self)
    }
}

extension UITableViewCell: ReusableViewProtocol{
    static var identifier: String{
        return String(describing: self)
    }
}
