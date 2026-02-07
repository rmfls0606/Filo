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

    static let postDetailDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy년 M월 d일"
        return formatter
    }()
}

extension String {
    func toRelativeTimeString() -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = isoFormatter.date(from: self) ?? ISO8601DateFormatter().date(from: self)
        guard let date else { return self }
        
        let now = Date()
        let seconds = Int(now.timeIntervalSince(date))
        if seconds < 60 { return "방금" }
        
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)분" }
        
        let hours = minutes / 60
        if hours < 24 { return "\(hours)시간" }
        
        let days = hours / 24
        if days < 7 { return "\(days)일" }
        
        let weeks = days / 7
        if weeks < 4 { return "\(weeks)주" }
        
        let months = days / 30
        if months < 12 { return "\(months)개월" }
        
        let years = days / 365
        return "\(years)년"
    }
    func toOrderDateString() -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = isoFormatter.date(from: self) ?? ISO8601DateFormatter().date(from: self)
        guard let date else { return self }
        return DateFormatter.orderDateFormatter.string(from: date)
    }

    func toPostDetailDateString() -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = isoFormatter.date(from: self) ?? ISO8601DateFormatter().date(from: self)
        guard let date else { return self }
        return DateFormatter.postDetailDateFormatter.string(from: date)
    }
}
