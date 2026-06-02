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
import MailCore
import MailCoreUI
import MailResources
import SwiftUI

extension View {
    func euriaFloatingPanel(
        user: UserProfile,
        messages: [Message]?,
        origin: ActionOrigin,
        completionHandler: ((Action) -> Void)? = nil
    ) -> some View {
        modifier(
            EuriaFloatingPanel(
                user: user,
                messages: messages,
                origin: origin,
                completionHandler: completionHandler
            )
        )
    }
}

struct EuriaFloatingPanel: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    @EnvironmentObject private var mailboxManager: MailboxManager
    @EnvironmentObject private var threadViewState: ThreadViewState

    @State private var isShowingPanel = false

    let user: UserProfile
    let messages: [Message]?
    let origin: ActionOrigin
    let completionHandler: ((Action) -> Void)?

    func body(content: Content) -> some View {
        content
            .onChange(of: messages) { newValue in
                isShowingPanel = newValue != nil && !availableActions(for: newValue).isEmpty
            }
            .mailFloatingPanel(isPresented: $isShowingPanel, title: MailResourcesStrings.Localizable.askEuriaTitle) {
                VStack(alignment: .leading, spacing: 0) {
                    let availableActions = availableActions(for: messages)

                    ForEach(availableActions) { action in
                        if action != availableActions.first {
                            IKDivider()
                        }

                        MessageActionView(
                            targetMessages: messages ?? [],
                            action: action,
                            origin: origin,
                            isMultipleSelection: (messages ?? []).count > 1,
                            completionHandler: completionHandler
                        )
                    }
                }
            }
    }

    private func availableActions(for messages: [Message]?) -> [Action] {
        guard let messages else { return [] }

        let actions = Action.actionsForMessages(
            messages,
            origin: origin,
            userIsStaff: user.isStaff ?? false,
            userEmail: user.email,
            threadViewState: threadViewState,
            colorScheme: colorScheme,
            featureAvailableProvider: mailboxManager.featureAvailableProvider
        )

        return actions.euriaActions
    }
}
