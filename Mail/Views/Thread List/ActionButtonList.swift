//
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

import InfomaniakCore
import InfomaniakDI
import MailCore
import SwiftModalPresentation
import SwiftUI

struct ActionButtonList: View {
    @EnvironmentObject private var actionsManager: ActionsManager

    let actions: [Action]
    let messages: [Message]
    let origin: ActionOrigin
    let toggleMultipleSelection: (Bool) -> Void

    var body: some View {
        ForEach(actions) { action in
            Button(role: isDestructiveAction(action)) {
                guard action != .activeMultiSelect else {
                    toggleMultipleSelection(false)
                    return
                }
                Task {
                    try await actionsManager.performAction(
                        target: messages,
                        action: action,
                        origin: origin
                    )
                }
            } label: {
                Label {
                    Text(action.title)
                } icon: {
                    action.icon
                }
            }
        }
    }

    private func isDestructiveAction(_ action: Action) -> ButtonRole? {
        guard action != .archive else {
            return nil
        }
        return action.isDestructive ? .destructive : nil
    }
}
