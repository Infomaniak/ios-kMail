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

import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailResources
import SwiftUI

struct CalendarAttendeesView: View {
    @LazyInjectService private var matomoUtils: MatomoUtils

    @EnvironmentObject private var mailboxManager: MailboxManager

    @State private var isShowingAttendees = false
    @State private var isShowingAllAttendees = false

    let organizer: Attendee?
    let attendees: [Attendee]

    private var organizerContact: CommonContact? {
        guard let organizer else { return nil }
        return CommonContactCache.getOrCreateContact(contactConfiguration: .correspondent(
            correspondent: organizer,
            contextMailboxManager: mailboxManager
        ))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: UIPadding.regular) {
            Button {
                withAnimation {
                    isShowingAttendees.toggle()
                    matomoUtils.track(eventWithCategory: .calendarEvent, name: "attendees", value: isShowingAttendees)
                }
            } label: {
                HStack(spacing: UIPadding.small) {
                    Text(MailResourcesStrings.Localizable.buttonAttendees)
                    ChevronIcon(direction: isShowingAttendees ? .up : .down, shapeStyle: .tint)
                }
                .textStyle(.bodyAccent)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.ikLink(isInlined: true))
            .padding(.horizontal, value: .regular)

            if isShowingAttendees {
                VStack(alignment: .leading, spacing: UIPadding.regular) {
                    if let organizerContact {
                        HStack(spacing: UIPadding.small) {
                            AvatarView(
                                mailboxManager: mailboxManager,
                                contactConfiguration: .contact(contact: organizerContact),
                                size: 32
                            )

                            Text(MailResourcesStrings.Localizable.calendarOrganizerName(organizerContact.fullName))
                                .textStyle(.body)
                        }
                        .padding(.horizontal, value: .regular)
                    }

                    Button {
                        isShowingAllAttendees = true
                        matomoUtils.track(eventWithCategory: .calendarEvent, name: "seeAllAttendees")
                    } label: {
                        HStack(spacing: UIPadding.small) {
                            CalendarAttendeesStack(attendees: attendees)
                            Text(MailResourcesStrings.Localizable.buttonSee)
                                .textStyle(.bodyAccent)
                        }
                    }
                    .padding(.horizontal, UIPadding.regular - UIConstants.avatarBorderLineWidth / 2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .floatingPanel(
            isPresented: $isShowingAllAttendees,
            title: MailResourcesStrings.Localizable.attendeesListTitle(attendees.count)
        ) {
            CalendarAllAttendeesView(attendees: attendees)
        }
    }
}

#Preview {
    CalendarAttendeesView(
        organizer: PreviewHelper.sampleAttendee1,
        attendees: [PreviewHelper.sampleAttendee1, PreviewHelper.sampleAttendee2]
    )
    .environmentObject(PreviewHelper.sampleMailboxManager)
}
