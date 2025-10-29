/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

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
import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import SwiftUI

struct CalendarBodyView: View {
    @Environment(\.openURL) private var openURL

    @EnvironmentObject private var mailboxManager: MailboxManager

    @State private var isLoadingCalendarButton = false

    let event: CalendarEvent

    var body: some View {
        VStack(alignment: .leading, spacing: IKPadding.medium) {
            CalendarBodyDetailsView(event: event)

            if !event.attendees.isEmpty {
                CalendarAttendeesView(organizer: event.organizer, attendees: event.attendees.toArray())
            }

            Button(action: addEventToCalendar) {
                Text(MailResourcesStrings.Localizable.buttonOpenMyCalendar)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.ikBorderedProminent)
            .ikButtonLoading(isLoadingCalendarButton)
            .padding(.horizontal, value: .medium)
        }
        .padding(.vertical, value: .medium)
    }

    private func addEventToCalendar() {
        @InjectService var matomoUtils: MatomoUtils
        matomoUtils.track(eventWithCategory: .calendarEvent, name: "openInMyCalendar")

        Task { @MainActor in
            var eventToOpen = event

            if event.parent?.userStoredEvent == nil || event.parent?.userStoredEventDeleted == true {
                isLoadingCalendarButton = true
                guard let messageUid = event.parent?.message?.uid,
                      let storedEvent = try? await mailboxManager.importICSEventToCalendar(messageUid: messageUid) else {
                    isLoadingCalendarButton = false

                    @InjectService var snackbarPresenter: IKSnackBarPresentable
                    snackbarPresenter.show(message: MailResourcesStrings.Localizable.errorEventCouldNotBeOpenedInMyCalendar)
                    return
                }
                isLoadingCalendarButton = false
                eventToOpen = storedEvent
            }

            openURL(URLConstants.calendarEvent(eventToOpen).url)
        }
    }
}

#Preview {
    CalendarBodyView(event: PreviewHelper.sampleCalendarEvent)
        .environmentObject(PreviewHelper.sampleMailboxManager)
}
