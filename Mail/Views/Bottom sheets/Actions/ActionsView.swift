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

import InfomaniakCore
import InfomaniakCoreUI
import MailCore
import MailResources
import SwiftUI

enum ActionsViewContentHelper {
    private static func actionsForMessage(_ message: Message,
                                          userIsStaff: Bool) -> (quickActions: [Action], listActions: [Action]) {
        let archive = message.folder?.role != .archive
        let unread = !message.seen
        let star = message.flagged
        let tempListActions: [Action?] = [
            .openMovePanel,
            .reportJunk,
            unread ? .markAsRead : .markAsUnread,
            archive ? .archive : .moveToInbox,
            star ? .unstar : .star,
            userIsStaff ? .reportDisplayProblem : nil
        ]
        return (Action.quickActions, tempListActions.compactMap { $0 })
    }

    private static func actionsForMessagesInDifferentThreads(_ messages: [Message])
        -> (quickActions: [Action], listActions: [Action]) {
        let unread = messages.allSatisfy(\.seen)
        let quickActions: [Action] = [.openMovePanel, unread ? .markAsRead : .markAsUnread, .archive, .delete]

        let spam = messages.allSatisfy { $0.folder?.role == .spam }
        let star = messages.allSatisfy(\.flagged)

        let listActions: [Action] = [
            spam ? .nonSpam : .spam,
            star ? .unstar : .star
        ]

        return (quickActions, listActions)
    }

    private static func actionsForMessagesInSameThreads(_ messages: [Message])
        -> (quickActions: [Action], listActions: [Action]) {
        let archive = messages.first?.folder?.role != .archive
        let unread = messages.allSatisfy(\.seen)
        let star = messages.allSatisfy(\.flagged)

        let spam = messages.first?.folder?.role == .spam
        let spamAction: Action? = spam ? .nonSpam : .spam

        let tempListActions: [Action?] = [
            .openMovePanel,
            spamAction,
            unread ? .markAsRead : .markAsUnread,
            archive ? .archive : .moveToInbox,
            star ? .unstar : .star
        ]

        return (Action.quickActions, tempListActions.compactMap { $0 })
    }

    static func actionsForMessages(_ messages: [Message],
                                   userIsStaff: Bool) -> (quickActions: [Action], listActions: [Action]) {
        if messages.count == 1, let message = messages.first {
            return actionsForMessage(message, userIsStaff: userIsStaff)
        } else if Set(messages.compactMap(\.originalThread?.id)).count > 1 {
            return actionsForMessagesInDifferentThreads(messages)
        } else {
            return actionsForMessagesInSameThreads(messages)
        }
    }
}

struct ActionsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var actionsManager: ActionsManager

    private let targetMessages: [Message]
    private let quickActions: [Action]
    private let listActions: [Action]
    private let origin: ActionOrigin

    init(mailboxManager: MailboxManager,
         target messages: [Message],
         origin: ActionOrigin) {
        let userIsStaff = mailboxManager.account.user.isStaff ?? false
        let actions = ActionsViewContentHelper.actionsForMessages(messages, userIsStaff: userIsStaff)
        quickActions = actions.quickActions
        listActions = actions.listActions

        targetMessages = messages
        self.origin = origin
    }

    var body: some View {
        VStack(alignment: .leading, spacing: UIConstants.actionsViewSpacing) {
            HStack(alignment: .top, spacing: 16) {
                ForEach(quickActions) { action in
                    QuickActionView(targetMessages: targetMessages, action: action, origin: origin)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 16)
            .padding(.horizontal, 16)

            ForEach(listActions) { action in
                if action != listActions.first {
                    IKDivider()
                }

                MessageActionView(targetMessages: targetMessages, action: action, origin: origin)
                    .padding(.horizontal, UIConstants.actionsViewCellHorizontalPadding)
            }
        }
        .padding(.horizontal, UIConstants.actionsViewHorizontalPadding)
        .matomoView(view: [MatomoUtils.View.bottomSheet.displayName, "ActionsView"])
    }
}

struct ActionsView_Previews: PreviewProvider {
    static var previews: some View {
        ActionsView(
            mailboxManager: PreviewHelper.sampleMailboxManager,
            target: PreviewHelper.sampleThread.messages.toArray(),
            origin: .toolbar
        )
        .accentColor(AccentColor.pink.primary.swiftUIColor)
    }
}

struct QuickActionView: View {
    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var actionsManager: ActionsManager

    let targetMessages: [Message]
    let action: Action
    let origin: ActionOrigin

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
                }
            }
        } label: {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(accentColor.secondary.swiftUIColor)
                    .frame(maxWidth: 56, maxHeight: 56)
                    .aspectRatio(1, contentMode: .fit)
                    .overlay {
                        action.icon
                            .resizable()
                            .scaledToFit()
                            .padding(16)
                    }
                    .padding(.horizontal, 8)

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
        HStack(spacing: 24) {
            action.icon
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundColor(action == .reportDisplayProblem ? MailResourcesAsset.princeColor.swiftUIColor : .accentColor)
            Text(action.title)
                .foregroundColor(action == .reportDisplayProblem ? MailResourcesAsset.princeColor : MailResourcesAsset
                    .textPrimaryColor)
                .textStyle(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
