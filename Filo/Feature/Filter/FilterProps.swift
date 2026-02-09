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

    var defaultValue: Float {
        switch self {
        case .contrast:
            return 1.0
        case .saturation, .highlights:
            return 1.0
        default:
            return 0.0
        }
    }

    var valueRange: ClosedRange<Float> {
        switch self {
        case .blackPoint:
            return -0.07...0.07
        case .blur:
            return -5.0...5.0
        case .brightness:
            return -1.0...1.0
        case .contrast:
            return 0.8...1.2
        case .exposure:
            return -2.0...2.0
        case .highlights:
            return 0.0...2.0
        case .noise:
            return 0.0...0.1
        case .saturation:
            return 0.0...2.0
        case .shadows:
            return -1.0...1.0
        case .sharpness:
            return 0.0...2.0
        case .temperature:
            return -100.0...100.0
        case .vignette:
            return -1.0...1.0
        }
    }

    func clampedActualValue(_ value: Float) -> Float {
        min(max(value, valueRange.lowerBound), valueRange.upperBound)
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
