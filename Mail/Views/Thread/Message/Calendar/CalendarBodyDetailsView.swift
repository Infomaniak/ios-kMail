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
    static var calendar: CalendarLabelStyle {
        return CalendarLabelStyle()
    }
}

struct CalendarLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: UIPadding.regular) {
            configuration.icon
                .frame(width: IKIcon.Size.large.rawValue, height: IKIcon.Size.large.rawValue)
                .foregroundStyle(MailResourcesAsset.textSecondaryColor)
            configuration.title
                .textStyle(.body)
                .multilineTextAlignment(.leading)
        }
    }
}

struct CalendarBodyDetailsView: View {
    let event: CalendarEvent
    let iAmPartOfAttendees: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: UIPadding.regular) {
            if event.hasPassed {
                Label {
                    Text(MailResourcesStrings.Localizable.warningEventHasPassed)
                        .textStyle(.bodyWarning)
                } icon: {
                    IKIcon(MailResourcesAsset.warning.swiftUIImage, size: .large)
                }
                .labelStyle(.calendar)
            }

            Label(event.formattedDate, image: MailResourcesAsset.calendar.name)
                .labelStyle(.calendar)
            Label(event.formattedTime, image: MailResourcesAsset.clock.name)
                .labelStyle(.calendar)
            if let location = event.location {
                Label(location, image: MailResourcesAsset.pin.name)
                    .labelStyle(.calendar)
            }
            if !iAmPartOfAttendees {
                Label(MailResourcesStrings.Localizable.calendarNotInvited, image: MailResourcesAsset.socialMedia.name)
                    .labelStyle(.calendar)
            }

            if !event.hasPassed && iAmPartOfAttendees {
                WrappingHStack(
                    AttendeeState.allCases,
                    id: \.self,
                    spacing: .constant(UIPadding.small),
                    lineSpacing: UIPadding.small
                ) { choice in
                    CalendarChoiceButton(choice: choice, isSelected: false)
                }
            }
        }
        .padding(.horizontal, value: .regular)
    }
}

#Preview("Is Invited") {
    CalendarBodyDetailsView(event: PreviewHelper.sampleCalendarEvent, iAmPartOfAttendees: true)
}

#Preview("Is Not Invited") {
    CalendarBodyDetailsView(event: PreviewHelper.sampleCalendarEvent, iAmPartOfAttendees: false)
}
