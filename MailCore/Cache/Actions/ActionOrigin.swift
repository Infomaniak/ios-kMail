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

public struct UIActionState {
    private(set) var nearestMessagesActionsPanel: Binding<[Message]?>?
    private(set) var nearestDestructiveAlert: Binding<DestructiveActionAlertState?>?
    private(set) var nearestNoReplyAlert: Binding<NoReplyAlertState?>?
    private(set) var nearestMessagesToMoveSheet: Binding<[Message]?>?
    private(set) var nearestBlockSenderAlert: Binding<BlockRecipientAlertState?>?
    private(set) var nearestBlockSendersList: Binding<BlockRecipientState?>?
    private(set) var nearestReportedForPhishingMessagesAlert: Binding<[Message]?>?
    private(set) var nearestReportedForDisplayProblemMessageAlert: Binding<Message?>?
    private(set) var nearestShareMailLinkPanel: Binding<ShareMailLinkResult?>?
    private(set) var nearestMessagesToSnooze: Binding<[Message]?>?
    private(set) var messagesToDownload: Binding<[Message]?>?
    private(set) var messagesToProcessWithEuria: Binding<[Message]?>?
    private(set) var nearestMessageToRemind: Binding<Message?>?

    public init(
        nearestMessagesActionsPanel: Binding<[Message]?>? = nil,
        nearestDestructiveAlert: Binding<DestructiveActionAlertState?>? = nil,
        nearestNoReplyAlert: Binding<NoReplyAlertState?>? = nil,
        nearestMessagesToMoveSheet: Binding<[Message]?>? = nil,
        nearestBlockSenderAlert: Binding<BlockRecipientAlertState?>? = nil,
        nearestBlockSendersList: Binding<BlockRecipientState?>? = nil,
        nearestReportedForPhishingMessagesAlert: Binding<[Message]?>? = nil,
        nearestReportedForDisplayProblemMessageAlert: Binding<Message?>? = nil,
        nearestShareMailLinkPanel: Binding<ShareMailLinkResult?>? = nil,
        nearestMessagesToSnooze: Binding<[Message]?>? = nil,
        messagesToDownload: Binding<[Message]?>? = nil,
        messagesToProcessWithEuria: Binding<[Message]?>? = nil,
        nearestMessageToRemind: Binding<Message?>? = nil
    ) {
        self.nearestMessagesActionsPanel = nearestMessagesActionsPanel
        self.nearestDestructiveAlert = nearestDestructiveAlert
        self.nearestNoReplyAlert = nearestNoReplyAlert
        self.nearestMessagesToMoveSheet = nearestMessagesToMoveSheet
        self.nearestBlockSenderAlert = nearestBlockSenderAlert
        self.nearestBlockSendersList = nearestBlockSendersList
        self.nearestReportedForPhishingMessagesAlert = nearestReportedForPhishingMessagesAlert
        self.nearestReportedForDisplayProblemMessageAlert = nearestReportedForDisplayProblemMessageAlert
        self.nearestShareMailLinkPanel = nearestShareMailLinkPanel
        self.nearestMessagesToSnooze = nearestMessagesToSnooze
        self.messagesToDownload = messagesToDownload
        self.messagesToProcessWithEuria = messagesToProcessWithEuria
        self.nearestMessageToRemind = nearestMessageToRemind
    }
}

public struct ActionOrigin {
    public enum ActionOriginType: Equatable {
        case swipe(direction: SwipeDirection)
        case floatingPanelListAction(source: FloatingPanelSource)
        case floatingPanelQuickAction(source: FloatingPanelSource)
        case euriaActions
        case toolbar(mode: ToolbarMode)
        case multipleSelection
        case shortcut
        case threadHeader
    }

    public enum FloatingPanelSource {
        case threadList
        case messageList
        case message
    }

    public enum ToolbarMode: Equatable {
        case compact
        case large(group: LargeToolbarGroup)
    }

    public enum LargeToolbarGroup: Equatable {
        case move
        case reply
        case report
        case other
    }

    public enum SwipeDirection {
        case leading
        case trailing
    }

    public private(set) var type: ActionOriginType
    public private(set) var frozenFolder: Folder?
    public private(set) var thread: Thread?
    public private(set) var actionState: UIActionState

    init(
        type: ActionOriginType,
        folder: Folder? = nil,
        thread: Thread? = nil,
        actionState: UIActionState
    ) {
        self.type = type
        frozenFolder = folder?.freezeIfNeeded()
        self.thread = thread?.freezeIfNeeded()
        self.actionState = actionState
    }

    public static func toolbarLarge(
        group: LargeToolbarGroup,
        thread: Thread? = nil,
        actionState: UIActionState
    ) -> ActionOrigin {
        return ActionOrigin(
            type: .toolbar(mode: .large(group: group)),
            folder: thread?.folder,
            thread: thread,
            actionState: actionState
        )
    }

    public static func toolbarCompact(
        originFolder: Folder? = nil,
        actionState: UIActionState
    ) -> ActionOrigin {
        return ActionOrigin(
            type: .toolbar(mode: .compact),
            folder: originFolder,
            actionState: actionState
        )
    }

    public static func floatingPanelListAction(source: FloatingPanelSource,
                                               originFolder: Folder? = nil,
                                               actionState: UIActionState) -> ActionOrigin {
        return ActionOrigin(
            type: .floatingPanelListAction(source: source),
            folder: originFolder,
            actionState: actionState
        )
    }

    public static func floatingPanelQuickAction(source: FloatingPanelSource,
                                                originFolder: Folder? = nil,
                                                actionState: UIActionState) -> ActionOrigin {
        return ActionOrigin(
            type: .floatingPanelQuickAction(source: source),
            folder: originFolder,
            actionState: actionState
        )
    }

    public static func multipleSelection(originFolder: Folder? = nil,
                                         actionState: UIActionState) -> ActionOrigin {
        return ActionOrigin(
            type: .multipleSelection,
            folder: originFolder,
            actionState: actionState
        )
    }

    public static func swipe(
        direction: SwipeDirection,
        thread: Thread? = nil,
        actionState: UIActionState

    ) -> ActionOrigin {
        return ActionOrigin(
            type: .swipe(direction: direction),
            folder: thread?.folder,
            thread: thread,
            actionState: actionState
        )
    }

    public static func shortcut(originFolder: Folder? = nil,
                                actionState: UIActionState) -> ActionOrigin {
        ActionOrigin(
            type: .shortcut,
            folder: originFolder,
            actionState: actionState
        )
    }

    public static func threadHeader(
        originFolder: Folder? = nil,
        actionState: UIActionState
    ) -> ActionOrigin {
        return ActionOrigin(
            type: .threadHeader,
            folder: originFolder,
            actionState: actionState
        )
    }

    public static func euriaActions(actionState: UIActionState) -> ActionOrigin {
        return ActionOrigin(type: .euriaActions, actionState: actionState)
    }
}
