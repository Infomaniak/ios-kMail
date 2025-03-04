/*
 Infomaniak Mail - iOS App
 Copyright (C) 2023 Infomaniak Network SA

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
import InfomaniakCoreSwiftUI
import MailCore
import MailCoreUI
import MailResources
import SwiftUI

extension LabelStyle where Self == CalendarLabelStyle {
    static func calendar(_ warning: CalendarEventWarning? = nil) -> CalendarLabelStyle {
        return CalendarLabelStyle(warning: warning)
    }
}

struct CalendarLabelStyle: LabelStyle {
    let warning: CalendarEventWarning?

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: IKPadding.medium) {
            configuration.icon
                .frame(width: IKIconSize.large.rawValue, height: IKIconSize.large.rawValue)
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
    let calendar: Calendar
    let parser: RruleDecoder

    init(event: CalendarEvent) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        self.calendar = calendar
        parser = RruleDecoder(frequency: .daily, interval: nil, calendar: calendar, end: nil, count: nil, byDay: nil)

        self.event = event
    }

    private var frozenMe: Attendee? {
        return event.getMyFrozenAttendee(currentMailboxEmail: mailboxManager.mailbox.email)
    }

    private var iAmInvited: Bool {
        return frozenMe != nil
    }

    private var canReply: Bool {
        return event.isAnInvitation && !event.isCancelled && iAmInvited
    }

    var body: some View {
        VStack(alignment: .leading, spacing: IKPadding.medium) {
            if let warning = event.warning {
                Label { Text(warning.label) } icon: { MailResourcesAsset.warningFill.iconSize(.large) }
                    .labelStyle(.calendar(warning))
            }

            Group {
                Label(event.formattedDateTime, asset: MailResourcesAsset.calendarBadgeClock.swiftUIImage)
                if let rrule = event.rrule {
                    if let nextOccurrence = try? parser.getNextOccurrence(rrule, event.start) {
                        Label(
                            MailResourcesStrings.Localizable.nextEventOccurrence + " " + nextOccurrence
                                .formatted(.calendarDateFull),
                            asset: MailResourcesAsset.clockCounterclockwise.swiftUIImage
                        )
                    }
                }
                if let bookableResource = event.bookableResource {
                    Label(bookableResource.name, asset: MailResourcesAsset.door.swiftUIImage)
                } else {
                    if let location = event.location, !location.isEmpty {
                        Label(location, asset: MailResourcesAsset.pin.swiftUIImage)
                    }
                }
                if !iAmInvited && !event.attendees.isEmpty {
                    Label(MailResourcesStrings.Localizable.calendarNotInvited, asset: MailResourcesAsset.socialMedia.swiftUIImage)
                }
            }
            .labelStyle(.calendar())

            if canReply {
                CalendarChoiceButtonsStack(currentState: frozenMe?.state, messageUid: event.parent?.message?.uid)
            }
        }
        .padding(.horizontal, value: .medium)
    }
}

#Preview {
    CalendarBodyDetailsView(event: PreviewHelper.sampleCalendarEvent)
        .environmentObject(PreviewHelper.sampleMailboxManager)
}
