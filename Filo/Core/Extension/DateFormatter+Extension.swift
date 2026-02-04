//
//  DateFormatter+Extension.swift
//  Filo
//
//  Created by 이상민 on 2/5/26.
//

import Foundation

extension DateFormatter {
    static let orderDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yy.MM.dd(E)"
        return formatter
    }()
}

extension String {
    func toOrderDateString() -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = isoFormatter.date(from: self) ?? ISO8601DateFormatter().date(from: self)
        guard let date else { return self }
        return DateFormatter.orderDateFormatter.string(from: date)
    }
}
