/*
 Infomaniak Mail - iOS App
 Copyright (C) 2025 Infomaniak Network SA

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

import MailCore
import MailResources
import SwiftUI

struct SnoozedThreadHeaderView: View {
    @EnvironmentObject private var mailboxManager: MailboxManager

    @State private var isShowingScheduleFloatingPanel = false

    let date: Date
    let shouldDisplayActions: Bool
    let lastMessageFromThread: Message?

    var body: some View {
        MessageHeaderActionView(
            icon: MailResourcesAsset.alarmClockFilled.swiftUIImage,
            message: MailResourcesStrings.Localizable.snoozeAlertTitle(date.formatted(.messageHeader)),
            isFirst: true,
            shouldDisplayActions: shouldDisplayActions
        ) {
            Button(MailResourcesStrings.Localizable.buttonModify, action: edit)
            MessageHeaderDivider()
            Button(MailResourcesStrings.Localizable.buttonCancelReminder, action: cancel)
        }
        .scheduleFloatingPanel(
            isPresented: $isShowingScheduleFloatingPanel,
            type: .snooze,
            initialDate: date,
            completionHandler: updateSnoozeDate
        )
    }

    private func edit() {
        isShowingScheduleFloatingPanel = true
    }

    private func updateSnoozeDate(_ newDate: Date) {
        guard let lastMessageFromThread else { return }

        Task {
            do {
                try await mailboxManager.updateSnooze(messages: [lastMessageFromThread], until: newDate)
            } catch {
                // TODO: Do something
                print(error)
            }
        }
    }

    private func cancel() {
        guard let lastMessageFromThread else { return }

        Task {
            do {
                try await mailboxManager.deleteSnooze(messages: [lastMessageFromThread])
            } catch {
                // TODO: Do something
                print(error)
            }
        }
    }
}

#Preview {
    SnoozedThreadHeaderView(date: .now, shouldDisplayActions: true, lastMessageFromThread: nil)
}
