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

struct CalendarAttendeesStack: View {
    private let maxDisplayedAttendees = 3

    let attendees: [Recipient]

    private var displayedAttendees: [Recipient] {
        if attendees.count > 3 {
            return Array(attendees[0 ..< 3])
        } else {
            return attendees
        }
    }

    private var hiddenAttendees: Int {
        return max(0, attendees.count - maxDisplayedAttendees)
    }

    var body: some View {
        HStack(spacing: -6) {
            ForEach(displayedAttendees) { attendee in
                CalendarAttendeeAvatarView(recipient: attendee, choice: .yes)
            }

            if hiddenAttendees > 0 {
                Circle()
                    .fill(Color.gray)
                    .overlay {
                        Text("+\(hiddenAttendees)")
                            .foregroundStyle(Color.white)
                    }
                    .frame(width: 32, height: 32)
            }
        }
    }
}

#Preview {
    CalendarAttendeesStack(attendees: Array(repeating: PreviewHelper.sampleRecipient1, count: 4))
        .environmentObject(PreviewHelper.sampleMailboxManager)
}
