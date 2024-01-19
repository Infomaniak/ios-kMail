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

import MailCore
import SwiftUI

struct CalendarAttendeeCell: View {
    let recipient: Recipient

    var body: some View {
        HStack(spacing: UIPadding.small) {
            CalendarAttendeeAvatarView(recipient: recipient, choice: .yes)

            VStack(alignment: .leading, spacing: 0) {
                if !recipient.name.isEmpty && recipient.name != recipient.email {
                    Text(recipient.name)
                        .textStyle(.bodyMedium)
                }
                Text(recipient.email)
                    .textStyle(.bodySecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, value: .small)
        .padding(.horizontal, value: .regular)
    }
}

#Preview {
    List {
        CalendarAttendeeCell(recipient: PreviewHelper.sampleRecipient1)
        CalendarAttendeeCell(recipient: PreviewHelper.sampleRecipient5)
    }
    .listStyle(.plain)
    .environmentObject(PreviewHelper.sampleMailboxManager)
}
