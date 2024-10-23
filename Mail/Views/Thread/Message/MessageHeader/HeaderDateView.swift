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

import MailCoreUI
import MailResources
import SwiftUI

struct HeaderDateView: View {
    let date: Date
    let format: Date.ThreadFormatStyle.Style

    var body: some View {
        if date > .now {
            MailResourcesAsset.clock
                .iconSize(.small)
                .foregroundStyle(MailResourcesAsset.orangeColor)
        }
        Text(date, format: .thread(format))
            .lineLimit(1)
            .layoutPriority(1)
            .textStyle(.labelSecondary)
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
