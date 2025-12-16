//
//  FiloColors.swift
//  Filo
//
//  Created by 이상민 on 12/13/25.
//

import UIKit

enum Brand: String{
    case blackTurquoise
    case deepTurquoise
    case brightTurquoise
    
    var color: UIColor?{
        return UIColor(named: self.rawValue)
    }
}

enum GrayStyle: String{
    case gray0
    case gray15
    case gray30
    case gray45
    case gray60
    case gray75
    case gray90
    case gray100
    
    var color: UIColor?{
        return UIColor(named: self.rawValue)
    }
}
