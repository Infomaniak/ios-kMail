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

import DesignSystem
import MailCore
import MailCoreUI
import SwiftUI

struct HeaderDateView: View {
    let displayDate: DisplayDate
    let format: Date.ThreadFormatStyle.Style

    var body: some View {
        HStack(spacing: IKPadding.micro) {
            if let icon = displayDate.icon, let foreground = displayDate.iconForeground {
                icon
                    .iconSize(.small)
                    .foregroundStyle(foreground)
            }

            Text(displayDate.date, format: .thread(format))
                .lineLimit(1)
                .layoutPriority(1)
                .textStyle(.labelSecondary)
        }
    }
}

#Preview {
    VStack {
        HeaderDateView(displayDate: .normal(.now), format: .header)
        HeaderDateView(displayDate: .snoozed(.now.addingTimeInterval(3600)), format: .header)
        HeaderDateView(displayDate: .scheduled(.now.addingTimeInterval(3600)), format: .header)
    }
}
