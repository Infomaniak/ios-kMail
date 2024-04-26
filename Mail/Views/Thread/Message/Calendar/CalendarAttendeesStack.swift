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
import MailCoreUI
import MailResources
import SwiftUI

struct CalendarAttendeesStack: View {
    private let maxDisplayedAttendees = 3

    let attendees: [Attendee]

    private var displayedAttendees: [Attendee] {
        return Array(attendees.prefix(maxDisplayedAttendees))
    }

    private var hiddenAttendees: Int {
        return max(0, attendees.count - maxDisplayedAttendees)
    }

    var body: some View {
        HStack(alignment: .top, spacing: -8) {
            ForEach(displayedAttendees) { attendee in
                AttendeeAvatarView(attendee: attendee)
            }

            if hiddenAttendees > 0 {
                InitialsView(
                    initials: "+\(hiddenAttendees)",
                    color: MailResourcesAsset.textSecondaryColor.color,
                    size: 32 + UIConstants.avatarBorderLineWidth
                )
                .overlay {
                    Circle()
                        .stroke(MailResourcesAsset.backgroundColor.swiftUIColor, lineWidth: UIConstants.avatarBorderLineWidth)
                }
            }
        }
    }
}

#Preview {
    CalendarAttendeesStack(attendees: PreviewHelper.sampleAttendees)
        .environmentObject(PreviewHelper.sampleMailboxManager)
}
