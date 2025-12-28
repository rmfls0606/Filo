//
//  FilterProps.swift
//  Filo
//
//  Created by 이상민 on 12/29/25.
//

import Foundation

enum FilterProps: String, CaseIterable{
    case blackPoint
    case blur
    case brightness
    case contrast
    case exposure
    case highlights
    case noise
    case saturation
    case shadows
    case sharpness
    case temperature
    case vignette
    
    var title: String{
        self.rawValue.uppercased()
    }
}
