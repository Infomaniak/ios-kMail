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
import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import SwiftModalPresentation
import SwiftUI

struct CalendarAttendeesView: View {
    @LazyInjectService private var matomoUtils: MatomoUtils

    @Environment(\.currentUser) private var currentUser

    @EnvironmentObject private var mailboxManager: MailboxManager

    @State private var isShowingAttendees = false
    @ModalState private var isShowingAllAttendees = false

    let organizer: Attendee?
    let attendees: [Attendee]

    private var organizerContact: CommonContact? {
        guard let organizer else { return nil }
        return CommonContactCache.getOrCreateContact(contactConfiguration: .correspondent(
            correspondent: organizer,
            contextUser: currentUser.value,
            contextMailboxManager: mailboxManager
        ))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: IKPadding.medium) {
            Button {
                withAnimation {
                    isShowingAttendees.toggle()
                    matomoUtils.track(eventWithCategory: .calendarEvent, name: "attendees", value: isShowingAttendees)
                }
            } label: {
                HStack(spacing: IKPadding.mini) {
                    Text(MailResourcesStrings.Localizable.buttonAttendees)
                    ChevronIcon(direction: isShowingAttendees ? .up : .down, shapeStyle: .tint)
                }
                .textStyle(.bodyAccent)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.ikBorderless(isInlined: true))
            .padding(.horizontal, value: .medium)

            if isShowingAttendees {
                VStack(alignment: .leading, spacing: IKPadding.medium) {
                    if let organizerContact {
                        HStack(spacing: IKPadding.mini) {
                            AvatarView(
                                mailboxManager: mailboxManager,
                                contactConfiguration: .contact(contact: organizerContact),
                                size: 32
                            )

                            Text(MailResourcesStrings.Localizable.calendarOrganizerName(organizerContact.fullName))
                                .textStyle(.body)
                        }
                        .padding(.horizontal, value: .medium)
                    }

                    Button {
                        isShowingAllAttendees = true
                        matomoUtils.track(eventWithCategory: .calendarEvent, name: "seeAllAttendees")
                    } label: {
                        HStack(spacing: IKPadding.mini) {
                            CalendarAttendeesStack(attendees: attendees)
                            Text(MailResourcesStrings.Localizable.buttonSee)
                                .textStyle(.bodyAccent)
                        }
                    }
                    .padding(.horizontal, IKPadding.medium - UIConstants.avatarBorderLineWidth / 2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .mailFloatingPanel(
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
    .environment(\.currentUser, MandatoryEnvironmentContainer(value: PreviewHelper.sampleUser))
}
