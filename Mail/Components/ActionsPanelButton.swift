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

import MailCore
import SwiftUI

struct ActionsPanelButton<Content: View>: View {
    @Environment(\.dismiss) private var dismiss

    @State private var actionMessages: [Message]?

    let messages: [Message]
    let originFolder: Folder?
    let panelSource: ActionOrigin.FloatingPanelSource
    var popoverArrowEdge: Edge = .top
    @ViewBuilder var label: () -> Content

    var body: some View {
        Button {
            actionMessages = messages
        } label: {
            label()
        }
        .actionsPanel(
            messages: $actionMessages,
            originFolder: originFolder,
            panelSource: panelSource,
            popoverArrowEdge: popoverArrowEdge
        ) { action in
            if action == .markAsUnread || action == .snooze || action == .modifySnooze {
                dismiss()
            }
        }
    }
}
