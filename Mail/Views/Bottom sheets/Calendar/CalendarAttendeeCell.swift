/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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
import InfomaniakCoreSwiftUI
import MailCore
import MailCoreUI
import SwiftUI

struct CalendarAttendeeCell: View {
    @Environment(\.currentUser) private var currentUser
    @EnvironmentObject private var mailboxManager: MailboxManager

    let attendee: Attendee

    private var cachedContact: CommonContact {
        return CommonContactCache.getOrCreateContact(contactConfiguration: .correspondent(
            correspondent: attendee,
            contextUser: currentUser.value,
            contextMailboxManager: mailboxManager
        ))
    }

    var body: some View {
        HStack(spacing: IKPadding.mini) {
            AttendeeAvatarView(attendee: attendee)

            VStack(alignment: .leading, spacing: 0) {
                if !cachedContact.fullName.isEmpty && cachedContact.fullName != attendee.email {
                    Text(cachedContact.fullName)
                        .textStyle(.bodyMedium)
                }
                Text(cachedContact.email)
                    .textStyle(.bodySecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, value: .mini)
        .padding(.horizontal, value: .medium)
    }
}

#Preview {
    List {
        CalendarAttendeeCell(attendee: PreviewHelper.sampleAttendee1)
        CalendarAttendeeCell(attendee: PreviewHelper.sampleAttendee2)
    }
    .listStyle(.plain)
    .environmentObject(PreviewHelper.sampleMailboxManager)
    .environment(\.currentUser, MandatoryEnvironmentContainer(value: PreviewHelper.sampleUser))
}
