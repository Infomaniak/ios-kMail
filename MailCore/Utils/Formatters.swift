/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import Foundation

// MARK: Date

public extension Date {
    struct ThreadFormatStyle: Foundation.FormatStyle {
        // swiftlint:disable:next nesting
        public enum Style: Codable, Equatable, Hashable {
            case list
            case header
        }

        private let style: Style

        init(style: Style) {
            self.style = style
        }

        public func format(_ value: Date) -> String {
            switch style {
            case .list:
                return formatToCustomRelative(value)
            case .header:
                return formatToMessageHeaderRelative(value)
            }
        }

        private func formatToCustomRelative(_ date: Date) -> String {
            if Calendar.current.isDateInToday(date) {
                return date.formatted(date: .omitted, time: .shortened)
            } else if date > .now {
                let dateFormatter = DateFormatter()

                dateFormatter.dateStyle = .short
                dateFormatter.timeStyle = .short
                dateFormatter.doesRelativeDateFormatting = true

                return dateFormatter.string(from: date)
            } else if Calendar.current.isDateInYesterday(date) {
                let dateMidnight = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: date)!
                return dateMidnight.formatted(.relative(presentation: .named))
            } else if let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: .now), date > lastWeek {
                return date.formatted(.dateTime.weekday(.wide))
            } else if Calendar.current.isDate(date, equalTo: .now, toGranularity: .year) {
                return date.formatted(.dateTime.day().month())
            } else {
                return date.formatted(date: .numeric, time: .omitted)
            }
        }

        private func formatToMessageHeaderRelative(_ date: Date) -> String {
            if date > .now {
                let dateFormatter = DateFormatter()

                dateFormatter.dateStyle = .long
                dateFormatter.timeStyle = .short
                dateFormatter.doesRelativeDateFormatting = true

                return dateFormatter.string(from: date)
            } else if Calendar.current.isDateInToday(date) {
                return date.formatted(date: .omitted, time: .shortened)
            } else if Calendar.current.isDateInYesterday(date) {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .long
                dateFormatter.timeStyle = .short
                dateFormatter.formattingContext = .middleOfSentence
                dateFormatter.doesRelativeDateFormatting = true
                return dateFormatter.string(from: date)
            } else if Calendar.current.isDate(date, equalTo: .now, toGranularity: .year) {
                return date.formatted(.dateTime.day().month().hour().minute())
            } else {
                return date.formatted(.dateTime.year().day().month().hour().minute())
            }
        }
    }
}

public extension FormatStyle where Self == Date.FormatStyle {
    static var calendarDateFull: Date.FormatStyle {
        return .dateTime.weekday(.wide).day().month(.wide).year()
    }

    static var calendarDateShort: Date.FormatStyle {
        return .dateTime.day().month().year()
    }

    static var calendarTime: Date.FormatStyle {
        return .dateTime.hour().minute()
    }

    static var calendarDateTime: Date.FormatStyle {
        return .dateTime.day().month().year().hour().minute()
    }

    static func thread(_ style: Date.ThreadFormatStyle.Style) -> Date.ThreadFormatStyle {
        return .init(style: style)
    }

    static var messageHeader: Date.FormatStyle {
        return .dateTime.day().month().year().hour().minute()
    }

    static var scheduleOption: Date.FormatStyle {
        return .dateTime.weekday(.abbreviated).day().month(.abbreviated).hour().minute()
    }
}

// MARK: ByteCount

public extension FormatStyle where Self == ByteCountFormatStyle {
    static var defaultByteCount: ByteCountFormatStyle {
        return .byteCount(style: .binary)
    }
}

// MARK: Int

public struct CappedCountFormatStyle: FormatStyle, Sendable {
    let maximum: Int

    public func format(_ value: Int) -> String {
        if value > maximum {
            return "\(maximum)+"
        } else {
            return "\(value)"
        }
    }
}

public extension FormatStyle where Self == CappedCountFormatStyle {
    static var indicatorCappedCount: CappedCountFormatStyle {
        return CappedCountFormatStyle(maximum: 99)
    }
}
