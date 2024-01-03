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

struct CalendarAttendeesView: View {
    @EnvironmentObject private var mailboxManager: MailboxManager

    @State private var isShowingAttendees = false

    let organizer = PreviewHelper.sampleRecipient4
    let attendees = Array(repeating: PreviewHelper.sampleRecipient1, count: 4)

    var body: some View {
        VStack(alignment: .leading, spacing: UIPadding.small) {
            Button {
                withAnimation {
                    isShowingAttendees.toggle()
                }
            } label: {
                HStack(spacing: UIPadding.small) {
                    Text("Participants")
                    ChevronIcon(direction: isShowingAttendees ? .up : .down, shapeStyle: .tint)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.ikLink(isInlined: true))

            if isShowingAttendees {
                VStack(alignment: .leading, spacing: UIPadding.regular) {
                    HStack(spacing: UIPadding.regular) {
                        AvatarView(
                            mailboxManager: mailboxManager,
                            contactConfiguration: .recipient(recipient: organizer, contextMailboxManager: mailboxManager),
                            size: 32
                        )

                        Text("Lucien Cheval (Organisateur)")
                            .textStyle(.body)
                    }

                    Button {
                        // TODO: Show bottom sheet with attendees
                    } label: {
                        HStack(spacing: UIPadding.regular) {
                            CalendarAttendeesStack(attendees: attendees)
                            Text("Consulter")
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    CalendarAttendeesView()
        .environmentObject(PreviewHelper.sampleMailboxManager)
}
