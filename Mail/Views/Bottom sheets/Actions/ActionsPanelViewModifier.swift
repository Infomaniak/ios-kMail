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

import Foundation
import MailCore
import SwiftUI

extension View {
    func actionsPanel(actionsTarget: Binding<ActionsTarget?>, completionHandler: (() -> Void)? = nil) -> some View {
        return modifier(ActionsPanelViewModifier(actionsTarget: actionsTarget, completionHandler: completionHandler))
    }
}

struct ActionsPanelViewModifier: ViewModifier {
    @EnvironmentObject private var mailboxManager: MailboxManager
    @EnvironmentObject private var navigationStore: NavigationStore

    @StateObject private var moveSheet = MoveSheet()

    @Binding var actionsTarget: ActionsTarget?
    @State var reportJunkActionsTarget: ActionsTarget?
    @State var reportedForPhishingMessage: Message?

    var completionHandler: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .floatingPanel(item: $actionsTarget) { target in
                ActionsView(mailboxManager: mailboxManager,
                            target: target,
                            moveSheet: moveSheet,
                            messageReply: $navigationStore.messageReply,
                            reportJunkActionsTarget: $reportJunkActionsTarget) {
                    completionHandler?()
                }
            }
            .sheet(isPresented: $moveSheet.isShowing) {
                if case .move(let folderId, let handler) = moveSheet.state {
                    MoveEmailView.sheetView(from: folderId, moveHandler: handler)
                }
            }
            .floatingPanel(item: $reportJunkActionsTarget) { target in
                ReportJunkView(mailboxManager: mailboxManager,
                               target: target,
                               reportedForPhishingMessage: $reportedForPhishingMessage)
            }
            .customAlert(item: $reportedForPhishingMessage) { message in
                ReportPhishingView(message: message)
            }
    }
}
