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

    func clampedActualValue(_ value: Float) -> Float {
        switch self {
        case .sharpness, .noise:
            return max(0.0, value)
        default:
            return value
        }
    }
}

struct FilterPropItem{
    let prop: FilterProps
    let isSelected: Bool
}

struct FilterImagePropsEntity{
    let blackPoint: Double
    let blur: Double
    let brightness: Double
    let contrast: Double
    let exposure: Double
    let highlights: Double
    let noise: Double
    let saturation: Double
    let shadows: Double
    let sharpness: Double
    let temperature: Double
    let vignette: Double
}
