/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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
import InfomaniakCoreUI
import MailCore
import MailCoreUI
import MailResources
import SwiftUI

struct ActionsView: View {
    private let targetMessages: [Message]
    private let quickActions: [Action]
    private let listActions: [Action]
    private let origin: ActionOrigin
    private let completionHandler: ((Action) -> Void)?

    init(mailboxManager: MailboxManager,
         target messages: [Message],
         origin: ActionOrigin,
         completionHandler: ((Action) -> Void)? = nil) {
        let userIsStaff = mailboxManager.account.user.isStaff ?? false
        let actions = Action.actionsForMessages(messages, origin: origin, userIsStaff: userIsStaff)
        quickActions = actions.quickActions
        listActions = actions.listActions

        targetMessages = messages
        self.origin = origin
        self.completionHandler = completionHandler
    }

    var body: some View {
        VStack(alignment: .leading, spacing: UIPadding.small) {
            HStack(alignment: .top, spacing: UIPadding.regular) {
                ForEach(quickActions) { action in
                    QuickActionView(
                        targetMessages: targetMessages,
                        action: action,
                        origin: origin,
                        completionHandler: completionHandler
                    )
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, UIPadding.regular)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(listActions) { action in
                    if action != listActions.first {
                        IKDivider()
                    }

                    MessageActionView(
                        targetMessages: targetMessages,
                        action: action,
                        origin: origin,
                        completionHandler: completionHandler
                    )
                }
            }
        }
        .matomoView(view: [MatomoUtils.View.bottomSheet.displayName, "ActionsView"])
    }
}

#Preview {
    ActionsView(
        mailboxManager: PreviewHelper.sampleMailboxManager,
        target: PreviewHelper.sampleThread.messages.toArray(),
        origin: .toolbar(originFolder: nil)
    )
    .accentColor(AccentColor.pink.primary.swiftUIColor)
}

struct QuickActionView: View {
    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var actionsManager: ActionsManager

    let targetMessages: [Message]
    let action: Action
    let origin: ActionOrigin
    var completionHandler: ((Action) -> Void)?

    var body: some View {
        Button {
            dismiss()
            Task {
                await tryOrDisplayError {
                    try await actionsManager.performAction(
                        target: targetMessages,
                        action: action,
                        origin: origin
                    )
                    completionHandler?(action)
                }
            }
        } label: {
            VStack(spacing: UIPadding.small) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(accentColor.secondary.swiftUIColor)
                    .frame(maxWidth: 56, maxHeight: 56)
                    .aspectRatio(1, contentMode: .fit)
                    .overlay {
                        action.icon
                            .resizable()
                            .scaledToFit()
                            .padding(value: .regular)
                    }

                let title = action.shortTitle ?? action.title
                Text(title)
                    .textStyle(.labelMediumAccent)
                    .lineLimit(title.split(separator: " ").count > 1 ? nil : 1)
            }
        }
    }
}

struct MessageActionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var actionsManager: ActionsManager

    let targetMessages: [Message]
    let action: Action
    let origin: ActionOrigin
    var completionHandler: ((Action) -> Void)?

    var body: some View {
        Button {
            dismiss()
            Task {
                await tryOrDisplayError {
                    try await actionsManager.performAction(
                        target: targetMessages,
                        action: action,
                        origin: origin
                    )
                    completionHandler?(action)
                }
            }
        } label: {
            ActionButtonLabel(action: action)
        }
    }
}

struct ActionButtonLabel: View {
    let action: Action
    var body: some View {
        HStack(spacing: UIPadding.regular) {
            action.icon
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundStyle(action == .reportDisplayProblem ? MailResourcesAsset.princeColor.swiftUIColor : .accentColor)
            Text(action.title)
                .foregroundStyle(action == .reportDisplayProblem ? MailResourcesAsset.princeColor : MailResourcesAsset
                    .textPrimaryColor)
                .textStyle(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(value: .regular)
    }
}
