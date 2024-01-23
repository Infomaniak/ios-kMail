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
    let event: CalendarEvent
    let attachmentMethod: AttachmentEventMethod?
    let me: Attendee?

    private var canReply: Bool {
        return (attachmentMethod == .request || attachmentMethod == nil) && event.warning != .isCancelled && me != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: UIPadding.regular) {
            if let warning = event.warning {
                Label { Text(warning.label) } icon: { IKIcon(MailResourcesAsset.warning, size: .large) }
                    .labelStyle(.calendar(warning))
            }

            Label(event.formattedDateTime, image: MailResourcesAsset.calendarBadgeClock.name)
                .labelStyle(.calendar())
            if let location = event.location {
                Label(location, image: MailResourcesAsset.pin.name)
                    .labelStyle(.calendar())
            }
            if me == nil && !event.attendees.isEmpty {
                Label(MailResourcesStrings.Localizable.calendarNotInvited, image: MailResourcesAsset.socialMedia.name)
                    .labelStyle(.calendar())
            }

            if canReply {
                WrappingHStack(
                    AttendeeState.allCases,
                    id: \.self,
                    spacing: .constant(UIPadding.small),
                    lineSpacing: UIPadding.small
                ) { choice in
                    CalendarChoiceButton(choice: choice, isSelected: me?.state == choice)
                }
            }
        }
        .padding(.horizontal, value: .regular)
    }
}

#Preview("Is Invited") {
    CalendarBodyDetailsView(
        event: PreviewHelper.sampleCalendarEvent,
        attachmentMethod: .request,
        me: PreviewHelper.sampleAttendee1
    )
}

#Preview("Is Not Invited") {
    CalendarBodyDetailsView(event: PreviewHelper.sampleCalendarEvent, attachmentMethod: .request, me: nil)
}
