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

import DesignSystem
import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import SwiftUI

struct ActionsView: View {
    private let targetMessages: [Message]
    private let quickActions: [Action]
    private let listActions: [Action]
    private let origin: ActionOrigin
    private let isMultipleSelection: Bool
    private let completionHandler: ((Action) -> Void)?

    init(user: UserProfile,
         target messages: [Message],
         origin: ActionOrigin,
         isMultipleSelection: Bool = false,
         completionHandler: ((Action) -> Void)? = nil) {
        let userIsStaff = user.isStaff ?? false
        let actions = Action.actionsForMessages(messages, origin: origin, userIsStaff: userIsStaff, userEmail: user.email)
        quickActions = actions.quickActions
        listActions = actions.listActions

        targetMessages = messages
        self.isMultipleSelection = isMultipleSelection
        self.origin = origin
        self.completionHandler = completionHandler
    }

    var body: some View {
        VStack(alignment: .leading, spacing: IKPadding.mini) {
            HStack(alignment: .top, spacing: IKPadding.medium) {
                ForEach(quickActions) { action in
                    QuickActionView(
                        targetMessages: targetMessages,
                        action: action,
                        origin: origin,
                        isMultipleSelection: isMultipleSelection,
                        completionHandler: completionHandler
                    )
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, IKPadding.medium)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(listActions) { action in
                    if action != listActions.first {
                        IKDivider()
                    }

                    MessageActionView(
                        targetMessages: targetMessages,
                        action: action,
                        origin: origin,
                        isMultipleSelection: isMultipleSelection,
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
        user: PreviewHelper.sampleUser,
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
    let isMultipleSelection: Bool
    var completionHandler: ((Action) -> Void)?

    var body: some View {
        Button {
            @InjectService var matomo: MatomoUtils
            dismiss()
            Task {
                await tryOrDisplayError {
                    try await actionsManager.performAction(
                        target: targetMessages,
                        action: action,
                        origin: origin
                    )
                    completionHandler?(action)

                    matomo.trackAction(
                        action: action,
                        origin: origin,
                        numberOfItems: targetMessages.count,
                        isMultipleSelection: isMultipleSelection
                    )
                }
            }
        } label: {
            VStack(spacing: IKPadding.mini) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(accentColor.secondary.swiftUIColor)
                    .frame(maxWidth: 56, maxHeight: 56)
                    .aspectRatio(1, contentMode: .fit)
                    .overlay {
                        action.icon
                            .resizable()
                            .scaledToFit()
                            .padding(value: .medium)
                    }

                let title = action.shortTitle ?? action.title
                Text(title)
                    .textStyle(.labelMediumAccent)
                    .lineLimit(title.split(separator: " ").count > 1 ? nil : 1)
            }
        }
        .accessibilityIdentifier(action.accessibilityIdentifier)
    }
}

struct MessageActionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var actionsManager: ActionsManager

    let targetMessages: [Message]
    let action: Action
    let origin: ActionOrigin
    let isMultipleSelection: Bool
    var completionHandler: ((Action) -> Void)?

    var body: some View {
        Button {
            @InjectService var matomo: MatomoUtils
            dismiss()
            Task {
                await tryOrDisplayError {
                    try await actionsManager.performAction(
                        target: targetMessages,
                        action: action,
                        origin: origin
                    )
                    completionHandler?(action)

                    matomo.trackAction(
                        action: action,
                        origin: origin,
                        numberOfItems: targetMessages.count,
                        isMultipleSelection: isMultipleSelection
                    )
                }
            }
        } label: {
            ActionButtonLabel(action: action)
        }
        .accessibilityIdentifier(action.accessibilityIdentifier)
    }
}

struct ActionButtonLabel: View {
    let action: Action

    var iconColor: MailResourcesColors {
        switch action {
        case .reportDisplayProblem:
            return MailResourcesAsset.princeColor
        case .logoutAccount, .deleteAccount:
            return MailResourcesAsset.redColor
        default:
            return UserDefaults.shared.accentColor.primary
        }
    }

    var titleColor: MailResourcesColors {
        switch action {
        case .reportDisplayProblem:
            return MailResourcesAsset.princeColor
        case .logoutAccount, .deleteAccount:
            return MailResourcesAsset.redColor
        default:
            return MailResourcesAsset.textPrimaryColor
        }
    }

    var body: some View {
        HStack(spacing: IKPadding.medium) {
            action.icon
                .iconSize(.large)
                .foregroundStyle(iconColor)
            Text(action.title)
                .foregroundStyle(titleColor)
                .textStyle(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(value: .medium)
    }
}
