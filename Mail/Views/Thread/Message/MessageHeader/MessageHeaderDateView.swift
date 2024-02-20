/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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

import SwiftUI

struct MessageHeaderDateView: View {
    let date: Date

    var body: some View {
        Text(date.messageHeaderRelativeFormatted)
            .lineLimit(1)
            .layoutPriority(1)
            .textStyle(.labelSecondary)
    }
}

#Preview {
    VStack {
        MessageHeaderDateView(date: .now)
        MessageHeaderDateView(date: .yesterday)
        MessageHeaderDateView(date: .lastWeek)
        MessageHeaderDateView(date: Date(timeIntervalSince1970: 0))
    }
}
