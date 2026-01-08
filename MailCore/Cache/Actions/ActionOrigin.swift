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

import Foundation
import SwiftUI

public struct ActionOrigin {
    public enum ActionOriginType: Equatable {
        case swipe
        case floatingPanel(source: FloatingPanelSource)
        case toolbar
        case multipleSelection
        case shortcut
        case threadHeader
    }

    public enum FloatingPanelSource {
        case threadList
        case messageList
        case message
    }

    public private(set) var type: ActionOriginType
    public private(set) var frozenFolder: Folder?

    private(set) var nearestMessagesActionsPanel: Binding<[Message]?>?
    private(set) var nearestDestructiveAlert: Binding<DestructiveActionAlertState?>?
    private(set) var nearestMessagesToMoveSheet: Binding<[Message]?>?
    private(set) var nearestBlockSenderAlert: Binding<BlockRecipientAlertState?>?
    private(set) var nearestBlockSendersList: Binding<BlockRecipientState?>?
    private(set) var nearestReportedForPhishingMessagesAlert: Binding<[Message]?>?
    private(set) var nearestReportedForDisplayProblemMessageAlert: Binding<Message?>?
    private(set) var nearestShareMailLinkPanel: Binding<ShareMailLinkResult?>?
    private(set) var nearestMessagesToSnooze: Binding<[Message]?>?
    private(set) var messagesToDownload: Binding<[Message]?>?

    init(
        type: ActionOriginType,
        folder: Folder? = nil,
        nearestMessagesActionsPanel: Binding<[Message]?>? = nil,
        nearestDestructiveAlert: Binding<DestructiveActionAlertState?>? = nil,
        nearestMessagesToMoveSheet: Binding<[Message]?>? = nil,
        nearestBlockSenderAlert: Binding<BlockRecipientAlertState?>? = nil,
        nearestBlockSendersList: Binding<BlockRecipientState?>? = nil,
        nearestReportedForPhishingMessagesAlert: Binding<[Message]?>? = nil,
        nearestReportedForDisplayProblemMessageAlert: Binding<Message?>? = nil,
        nearestShareMailLinkPanel: Binding<ShareMailLinkResult?>? = nil,
        nearestMessagesToSnooze: Binding<[Message]?>? = nil,
        messagesToDownload: Binding<[Message]?>? = nil
    ) {
        self.type = type
        frozenFolder = folder?.freezeIfNeeded()
        self.nearestMessagesActionsPanel = nearestMessagesActionsPanel
        self.nearestDestructiveAlert = nearestDestructiveAlert
        self.nearestMessagesToMoveSheet = nearestMessagesToMoveSheet
        self.nearestBlockSenderAlert = nearestBlockSenderAlert
        self.nearestBlockSendersList = nearestBlockSendersList
        self.nearestReportedForPhishingMessagesAlert = nearestReportedForPhishingMessagesAlert
        self.nearestReportedForDisplayProblemMessageAlert = nearestReportedForDisplayProblemMessageAlert
        self.nearestShareMailLinkPanel = nearestShareMailLinkPanel
        self.nearestMessagesToSnooze = nearestMessagesToSnooze
        self.messagesToDownload = messagesToDownload
    }

    public static func toolbar(originFolder: Folder? = nil,
                               nearestDestructiveAlert: Binding<DestructiveActionAlertState?>? = nil) -> ActionOrigin {
        return ActionOrigin(type: .toolbar, folder: originFolder, nearestDestructiveAlert: nearestDestructiveAlert)
    }

    public static func floatingPanel(source: FloatingPanelSource,
                                     originFolder: Folder? = nil,
                                     nearestDestructiveAlert: Binding<DestructiveActionAlertState?>? = nil,
                                     nearestMessagesToMoveSheet: Binding<[Message]?>? = nil,
                                     nearestBlockSenderAlert: Binding<BlockRecipientAlertState?>? = nil,
                                     nearestBlockSendersList: Binding<BlockRecipientState?>? = nil,
                                     nearestReportedForPhishingMessagesAlert: Binding<[Message]?>? = nil,
                                     nearestReportedForDisplayProblemMessageAlert: Binding<Message?>? = nil,
                                     nearestShareMailLinkPanel: Binding<ShareMailLinkResult?>? = nil,
                                     nearestMessagesToSnooze: Binding<[Message]?>? = nil,
                                     messagesToDownload: Binding<[Message]?>? = nil) -> ActionOrigin {
        return ActionOrigin(
            type: .floatingPanel(source: source),
            folder: originFolder,
            nearestDestructiveAlert: nearestDestructiveAlert,
            nearestMessagesToMoveSheet: nearestMessagesToMoveSheet,
            nearestBlockSenderAlert: nearestBlockSenderAlert,
            nearestBlockSendersList: nearestBlockSendersList,
            nearestReportedForPhishingMessagesAlert: nearestReportedForPhishingMessagesAlert,
            nearestReportedForDisplayProblemMessageAlert: nearestReportedForDisplayProblemMessageAlert,
            nearestShareMailLinkPanel: nearestShareMailLinkPanel,
            nearestMessagesToSnooze: nearestMessagesToSnooze,
            messagesToDownload: messagesToDownload
        )
    }

    public static func multipleSelection(originFolder: Folder? = nil,
                                         nearestDestructiveAlert: Binding<DestructiveActionAlertState?>? = nil,
                                         nearestMessagesToMoveSheet: Binding<[Message]?>? = nil) -> ActionOrigin {
        return ActionOrigin(
            type: .multipleSelection,
            folder: originFolder,
            nearestDestructiveAlert: nearestDestructiveAlert,
            nearestMessagesToMoveSheet: nearestMessagesToMoveSheet
        )
    }

    public static func swipe(
        originFolder: Folder? = nil,
        nearestMessagesActionsPanel: Binding<[Message]?>? = nil,
        nearestMessagesToMoveSheet: Binding<[Message]?>? = nil,
        nearestDestructiveAlert: Binding<DestructiveActionAlertState?>? = nil,
        nearestMessagesToSnooze: Binding<[Message]?>? = nil
    ) -> ActionOrigin {
        return ActionOrigin(
            type: .swipe,
            folder: originFolder,
            nearestMessagesActionsPanel: nearestMessagesActionsPanel,
            nearestDestructiveAlert: nearestDestructiveAlert,
            nearestMessagesToMoveSheet: nearestMessagesToMoveSheet,
            nearestMessagesToSnooze: nearestMessagesToSnooze
        )
    }

    public static func shortcut(originFolder: Folder? = nil,
                                nearestDestructiveAlert: Binding<DestructiveActionAlertState?>? = nil) -> ActionOrigin {
        ActionOrigin(type: .shortcut, folder: originFolder, nearestDestructiveAlert: nearestDestructiveAlert)
    }

    public static func threadHeader(originFolder: Folder? = nil,
                                    nearestMessagesToSnooze: Binding<[Message]?>? = nil) -> ActionOrigin {
        return ActionOrigin(type: .threadHeader, folder: originFolder, nearestMessagesToSnooze: nearestMessagesToSnooze)
    }
}
