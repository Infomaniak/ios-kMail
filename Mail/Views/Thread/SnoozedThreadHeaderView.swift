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
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var actionsManager: ActionsManager

    @State private var isShowingScheduleFloatingPanel = false

    let date: Date
    let messages: [Message]
    let folder: Folder?

    private var origin: ActionOrigin {
        return .threadHeader(originFolder: folder, nearestSchedulePanel: $isShowingScheduleFloatingPanel)
    }

    var body: some View {
        MessageHeaderActionView(
            icon: MailResourcesAsset.alarmClockFilled.swiftUIImage,
            message: MailResourcesStrings.Localizable.snoozeAlertTitle(date.formatted(.messageHeader)),
            isFirst: true,
            shouldDisplayActions: folder?.canAccessSnoozeActions ?? false
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
        Task {
            try await actionsManager.performAction(target: messages, action: .modifySnooze, origin: origin)
        }
    }

    private func updateSnoozeDate(_ newDate: Date) {
        Task {
            try await actionsManager.performSnooze(messages: messages, date: newDate, originFolder: folder)
            dismiss()
        }
    }

    private func cancel() {
        Task {
            try await actionsManager.performAction(target: messages, action: .cancelSnooze, origin: origin)
        }
    }
}

#Preview {
    SnoozedThreadHeaderView(date: .now, messages: [], folder: nil)
}
