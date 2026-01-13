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
        // Core Image가 안정적으로 처리할 수 있는 초기값/리셋값
        switch self {
        case .blackPoint: return 0.0
        case .blur: return 0.0
        case .brightness: return 0.0
        case .contrast: return 1.0
        case .exposure: return 0.0
        case .highlights: return 0.0
        case .noise: return 0.0
        case .saturation: return 1.0
        case .shadows: return 0.0
        case .sharpness: return 0.0
        case .temperature: return 0.0
        case .vignette: return 0.0
        }
    }
    
    var sliderRange: ClosedRange<Float> {
        // 실제 필터에 전달할 값 범위 (UI 슬라이더 -5~5를 여기에 매핑)
        switch self {
        case .blackPoint: return 0.0...0.2
        case .blur: return 0.0...20.0
        case .brightness: return -1.0...1.0
        case .contrast: return 0.5...1.5
        case .exposure: return -2.0...2.0
        case .highlights: return 0.0...1.0
        case .noise: return 0.0...0.1
        case .saturation: return 0.0...2.0
        case .shadows: return 0.0...1.0
        case .sharpness: return 0.0...2.0
        case .temperature: return -20.0...20.0
        case .vignette: return 0.0...2.0
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
