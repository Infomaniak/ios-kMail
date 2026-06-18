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
import KSuite
import MailCore
import MailCoreUI
import MailResources
import SwiftUI

struct ActionsView: View {
    @EnvironmentObject private var actionsProvider: ActionsProvider

    private var quickActions: [Action] {
        actionsProvider.actionsFor(origin: quickActionOrigin, messages: targetMessages)
    }

    private var listActions: [Action] {
        actionsProvider.actionsFor(origin: listActionOrigin, messages: targetMessages)
    }

    private let targetMessages: [Message]
    private let listActionOrigin: ActionOrigin
    private let quickActionOrigin: ActionOrigin
    private let isMultipleSelection: Bool
    private let completionHandler: ((Action) -> Void)?

    init(
        target messages: [Message],
        listActionOrigin: ActionOrigin,
        quickActionOrigin: ActionOrigin,
        isMultipleSelection: Bool,
        completionHandler: ((Action) -> Void)? = nil
    ) {
        targetMessages = messages
        self.listActionOrigin = listActionOrigin
        self.quickActionOrigin = quickActionOrigin
        self.isMultipleSelection = isMultipleSelection
        self.completionHandler = completionHandler
    }

    var body: some View {
        VStack(alignment: .leading, spacing: IKPadding.mini) {
            HStack(alignment: .top, spacing: IKPadding.medium) {
                ForEach(quickActions) { action in
                    QuickActionView(
                        targetMessages: targetMessages,
                        action: action,
                        origin: quickActionOrigin,
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
                        origin: listActionOrigin,
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
        target: PreviewHelper.sampleThread.messages.toArray(),
        listActionOrigin: .floatingPanelListAction(source: .message),
        quickActionOrigin: .floatingPanelQuickAction(source: .message),
        isMultipleSelection: false
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

    private static let sendEmailActions: Set<Action> = [.reply, .replyAll, .forward]

    private var isActionInactive: Bool {
        Self.sendEmailActions.contains(action) && !actionsManager.canSendEmails
    }

    var body: some View {
        Button(action: didTapButton) {
            VStack(spacing: IKPadding.mini) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isActionInactive ? MailResourcesAsset.hoverMenuBackground.swiftUIColor : accentColor.secondary
                        .swiftUIColor)
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
                    .foregroundStyle(isActionInactive ? MailResourcesAsset.grayActionColor.swiftUIColor : accentColor.primary
                        .swiftUIColor)
                    .textStyle(.labelMediumAccent)
                    .lineLimit(title.split(separator: " ").count > 1 ? nil : 1)
            }
        }
        .disabled(isActionInactive)
        .accessibilityIdentifier(action.accessibilityIdentifier)
    }

    private func didTapButton() {
        dismiss()

        Task {
            await tryOrDisplayError {
                try await actionsManager.performAction(
                    target: targetMessages,
                    action: action,
                    origin: origin
                )
                completionHandler?(action)

                @InjectService var matomo: MatomoUtils
                matomo.trackThreadBottomSheetAction(
                    action: action,
                    origin: origin,
                    numberOfItems: targetMessages.count,
                    isMultipleSelection: isMultipleSelection
                )
            }
        }
    }
}

struct MessageActionView: View {
    @Environment(\.locale) private var locale
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var actionsManager: ActionsManager
    @EnvironmentObject private var mailboxManager: MailboxManager

    let targetMessages: [Message]
    let action: Action
    let origin: ActionOrigin
    let isMultipleSelection: Bool
    var completionHandler: ((Action) -> Void)?

    private var badgeType: ActionButtonLabel.BadgeType {
        if action == .shareMailLink {
            let userLocalPack = mailboxManager.mailbox.pack
            if userLocalPack == .kSuiteFree || userLocalPack == .starterPack {
                return .kSuitePro
            } else if userLocalPack == .myKSuiteFree {
                return .myKSuite
            }
        }
        return .none
    }

    var body: some View {
        Button(action: didTapButton) {
            ActionButtonLabel(action: action, badgeType: badgeType)
        }
        .accessibilityIdentifier(action.accessibilityIdentifier)
    }

    private func didTapButton() {
        dismiss()

        Task {
            await tryOrDisplayError {
                try await actionsManager.performAction(
                    target: targetMessages,
                    action: action,
                    origin: origin,
                    locale: locale
                )
                completionHandler?(action)

                @InjectService var matomo: MatomoUtils
                matomo.trackThreadBottomSheetAction(
                    action: action,
                    origin: origin,
                    numberOfItems: targetMessages.count,
                    isMultipleSelection: isMultipleSelection
                )
            }
        }
    }
}

struct ActionButtonLabel: View {
    enum BadgeType {
        case none, myKSuite, kSuitePro
    }

    let action: Action
    let badgeType: BadgeType

    init(action: Action, badgeType: BadgeType) {
        self.action = action
        self.badgeType = badgeType
    }

    init(action: Action) {
        self.action = action
        badgeType = .none
    }

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

            if badgeType == .myKSuite {
                MyKSuitePlusChip()
            } else if badgeType == .kSuitePro {
                KSuiteProUpgradeChip()
            }
        }
        .padding(value: .medium)
    }
}
