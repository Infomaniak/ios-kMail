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

import InfomaniakCoreSwiftUI
import MailCore
import MailCoreUI
import MailResources
import SwiftUI

struct HeaderDateView: View {
    let date: Date
    let format: Date.ThreadFormatStyle.Style
    var isScheduled: Bool { date > .now }

    var body: some View {
        HStack(spacing: IKPadding.small) {
            if isScheduled {
                MailResourcesAsset.clock2
                    .iconSize(.small)
            }
            Text(date, format: .thread(format))
                .lineLimit(1)
                .layoutPriority(1)
                .textStyle(isScheduled ? .labelSchedule : .labelSecondary)
        }
        .foregroundStyle(MailResourcesAsset.scheduleDateColor.swiftUIColor)
    }
}

#Preview {
    VStack {
        HeaderDateView(date: .now, format: .header)
        HeaderDateView(date: .yesterday, format: .list)
        HeaderDateView(date: .lastWeek, format: .header)
        HeaderDateView(date: Date(timeIntervalSince1970: 0), format: .list)
        HeaderDateView(date: .distantFuture, format: .header)
    }
}