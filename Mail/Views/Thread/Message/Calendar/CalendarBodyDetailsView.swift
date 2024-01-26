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
import MailResources
import SwiftUI
import WrappingHStack

extension LabelStyle where Self == CalendarLabelStyle {
    static func calendar(_ warning: CalendarEventWarning? = nil) -> CalendarLabelStyle {
        return CalendarLabelStyle(warning: warning)
    }
}

struct CalendarLabelStyle: LabelStyle {
    let warning: CalendarEventWarning?

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: UIPadding.regular) {
            configuration.icon
                .frame(width: IKIcon.Size.large.rawValue, height: IKIcon.Size.large.rawValue)
                .foregroundStyle(warning?.color ?? MailResourcesAsset.textSecondaryColor.swiftUIColor)
            configuration.title
                .font(MailTextStyle.body.font)
                .foregroundStyle(warning?.color ?? MailTextStyle.body.color)
                .multilineTextAlignment(.leading)
        }
    }
}

struct CalendarBodyDetailsView: View {
    @EnvironmentObject private var mailboxManager: MailboxManager

    let event: CalendarEvent

    private var me: Attendee? {
        return event.getMyAttendee(currentMailboxEmail: mailboxManager.mailbox.email)
    }

    private var iAmInvited: Bool {
        return me != nil
    }

    private var canReply: Bool {
        let isAnInvitation = event.parent?.attachmentEventMethod == .request || event.parent?.attachmentEventMethod == nil
        let isNotCancelled = event.warning != .isCancelled

        return isAnInvitation && isNotCancelled && iAmInvited
    }

    var body: some View {
        VStack(alignment: .leading, spacing: UIPadding.regular) {
            if let warning = event.warning {
                Label { Text(warning.label) } icon: { IKIcon(MailResourcesAsset.warning, size: .large) }
                    .labelStyle(.calendar(warning))
            }

            Group {
                Label(event.formattedDateTime, image: MailResourcesAsset.calendarBadgeClock.name)
                if let location = event.location {
                    Label(location, image: MailResourcesAsset.pin.name)
                }
                if !iAmInvited && !event.attendees.isEmpty {
                    Label(MailResourcesStrings.Localizable.calendarNotInvited, image: MailResourcesAsset.socialMedia.name)
                }
            }
            .labelStyle(.calendar())

            if canReply {
                CalendarChoiceButtonsStack(currentState: me?.state, messageUid: event.parent?.message?.uid)
            }
        }
        .padding(.horizontal, value: .regular)
    }
}

#Preview {
    CalendarBodyDetailsView(event: PreviewHelper.sampleCalendarEvent)
        .environmentObject(PreviewHelper.sampleMailboxManager)
}
