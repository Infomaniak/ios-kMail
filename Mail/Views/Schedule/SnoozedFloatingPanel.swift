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
import SwiftUI

extension View {
    func snoozedFloatingPanel(
        messages: [Message]?,
        initialDate: Date?,
        folder: Folder?,
        completionHandler: ((Action) -> Void)? = nil
    ) -> some View {
        modifier(
            SnoozedFloatingPanel(
                messages: messages,
                initialDate: initialDate,
                folder: folder,
                completionHandler: completionHandler
            )
        )
    }
}

struct SnoozedFloatingPanel: ViewModifier {
    @EnvironmentObject private var actionsManager: ActionsManager

    @State private var isShowingPanel = false

    let messages: [Message]?
    let initialDate: Date?
    let folder: Folder?
    let completionHandler: ((Action) -> Void)?

    private var isUpdating: Bool {
        let messagesInFolder = messages?.filter { $0.folder?.remoteId == folder?.remoteId } ?? []
        return messagesInFolder.allSatisfy(\.isSnoozed)
    }

    func body(content: Content) -> some View {
        content
            .onChange(of: messages) { newValue in
                isShowingPanel = newValue != nil
            }
            .scheduleFloatingPanel(
                isPresented: $isShowingPanel,
                type: .snooze,
                isUpdating: isUpdating,
                initialDate: initialDate,
                completionHandler: handleSelectedDate
            )
    }

    private func handleSelectedDate(_ date: Date) {
        guard let messages else { return }

        Task {
            let action = try await actionsManager.performSnooze(messages: messages, date: date, originFolder: folder)
            completionHandler?(action)
        }
    }
}
