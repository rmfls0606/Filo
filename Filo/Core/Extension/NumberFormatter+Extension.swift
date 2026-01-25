//
//  NumberFormatter+Extension.swift
//  Filo
//
//  Created by 이상민 on 01/19/26.
//

import Foundation

extension NumberFormatter {
    static let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()
}

extension String {
    var digitsOnly: String {
        filter { $0.isNumber }
    }

    func formattedDecimal() -> String {
        let digits = digitsOnly
        guard let value = Int(digits) else { return "" }
        return NumberFormatter.decimalFormatter.string(from: NSNumber(value: value)) ?? digits
    }
}

extension Int{
    func formattedDecimal() -> String{
        return NumberFormatter.decimalFormatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
