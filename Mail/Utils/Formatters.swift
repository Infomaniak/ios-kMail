/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import Foundation

public extension Date {
    var customRelativeFormatted: String {
        if Calendar.current.isDateInToday(self) {
            return self.formatted(date: .omitted, time: .shortened)
        } else if Calendar.current.isDateInYesterday(self) {
            let dateMidnight = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: self)!
            return dateMidnight.formatted(.relative(presentation: .named))
        } else if Calendar.current.isDate(self, equalTo: .now, toGranularity: .weekOfYear) {
            return self.formatted(.dateTime.weekday(.wide))
        } else if Calendar.current.isDate(self, equalTo: .now, toGranularity: .year) {
            return self.formatted(.dateTime.day().month())
        } else {
            return self.formatted(date: .numeric, time: .omitted)
        }
    }
}

public extension FormatStyle where Self == ByteCountFormatStyle {
    static var defaultByteCount: ByteCountFormatStyle {
        return .byteCount(style: .binary)
    }
}
