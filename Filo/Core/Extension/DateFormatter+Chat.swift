//
//  DateFormatter+Chat.swift
//  Filo
//
//  Created by 이상민 on 2/6/26.
//

import Foundation

extension DateFormatter {
    static let chatTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "a HH:mm"
        return formatter
    }()

    static let chatDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yy.MM.dd"
        return formatter
    }()
}

extension String {
    func toChatTimestamp() -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = isoFormatter.date(from: self) ?? ISO8601DateFormatter().date(from: self)
        guard let date else { return self }
        if Calendar.current.isDateInToday(date) {
            return DateFormatter.chatTimeFormatter.string(from: date)
        }
        return DateFormatter.chatDateFormatter.string(from: date)
    }
}
