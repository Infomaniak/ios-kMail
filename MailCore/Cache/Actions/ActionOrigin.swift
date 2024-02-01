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
import SwiftUI

public struct ActionOrigin {
    public enum ActionOriginType: Equatable {
        case swipe
        case floatingPanel(source: FloatingPanelSource)
        case toolbar
        case multipleSelection
        case shortcut
    }

    public enum FloatingPanelSource {
        case threadList
        case messageList
    }

    public private(set) var type: ActionOriginType
    public private(set) var frozenFolder: Folder?

    private(set) var nearestMessagesActionsPanel: Binding<[Message]?>?
    private(set) var nearestFlushAlert: Binding<FlushAlertState?>?
    private(set) var nearestMessagesToMoveSheet: Binding<[Message]?>?
    private(set) var nearestReportJunkMessageActionsPanel: Binding<Message?>?
    private(set) var nearestReportedForPhishingMessageAlert: Binding<Message?>?
    private(set) var nearestReportedForDisplayProblemMessageAlert: Binding<Message?>?

    init(
        type: ActionOriginType,
        folder: Folder? = nil,
        nearestMessagesActionsPanel: Binding<[Message]?>? = nil,
        nearestFlushAlert: Binding<FlushAlertState?>? = nil,
        nearestMessagesToMoveSheet: Binding<[Message]?>? = nil,
        nearestReportJunkMessageActionsPanel: Binding<Message?>? = nil,
        nearestReportedForPhishingMessageAlert: Binding<Message?>? = nil,
        nearestReportedForDisplayProblemMessageAlert: Binding<Message?>? = nil
    ) {
        self.type = type
        frozenFolder = folder?.freezeIfNeeded()
        self.nearestMessagesActionsPanel = nearestMessagesActionsPanel
        self.nearestFlushAlert = nearestFlushAlert
        self.nearestMessagesToMoveSheet = nearestMessagesToMoveSheet
        self.nearestReportJunkMessageActionsPanel = nearestReportJunkMessageActionsPanel
        self.nearestReportedForPhishingMessageAlert = nearestReportedForPhishingMessageAlert
        self.nearestReportedForDisplayProblemMessageAlert = nearestReportedForDisplayProblemMessageAlert
    }

    public static func toolbar(originFolder: Folder? = nil,
                               nearestFlushAlert: Binding<FlushAlertState?>? = nil) -> ActionOrigin {
        return ActionOrigin(type: .toolbar, folder: originFolder, nearestFlushAlert: nearestFlushAlert)
    }

    public static func floatingPanel(source: FloatingPanelSource,
                                     originFolder: Folder? = nil,
                                     nearestFlushAlert: Binding<FlushAlertState?>? = nil,
                                     nearestMessagesToMoveSheet: Binding<[Message]?>? = nil,
                                     nearestReportJunkMessageActionsPanel: Binding<Message?>? = nil,
                                     nearestReportedForPhishingMessageAlert: Binding<Message?>? = nil,
                                     nearestReportedForDisplayProblemMessageAlert: Binding<Message?>? = nil) -> ActionOrigin {
        return ActionOrigin(
            type: .floatingPanel(source: source),
            folder: originFolder,
            nearestFlushAlert: nearestFlushAlert,
            nearestMessagesToMoveSheet: nearestMessagesToMoveSheet,
            nearestReportJunkMessageActionsPanel: nearestReportJunkMessageActionsPanel,
            nearestReportedForPhishingMessageAlert: nearestReportedForPhishingMessageAlert,
            nearestReportedForDisplayProblemMessageAlert: nearestReportedForDisplayProblemMessageAlert
        )
    }

    public static func multipleSelection(originFolder: Folder? = nil,
                                         nearestFlushAlert: Binding<FlushAlertState?>? = nil) -> ActionOrigin {
        return ActionOrigin(type: .multipleSelection, folder: originFolder, nearestFlushAlert: nearestFlushAlert)
    }

    public static func swipe(
        originFolder: Folder? = nil,
        nearestMessagesActionsPanel: Binding<[Message]?>? = nil,
        nearestMessagesToMoveSheet: Binding<[Message]?>? = nil,
        nearestFlushAlert: Binding<FlushAlertState?>? = nil
    ) -> ActionOrigin {
        return ActionOrigin(type: .swipe,
                            folder: originFolder,
                            nearestMessagesActionsPanel: nearestMessagesActionsPanel,
                            nearestFlushAlert: nearestFlushAlert,
                            nearestMessagesToMoveSheet: nearestMessagesToMoveSheet)
    }

    public static func shortcut(originFolder: Folder? = nil,
                                nearestFlushAlert: Binding<FlushAlertState?>? = nil) -> ActionOrigin {
        ActionOrigin(type: .shortcut, folder: originFolder, nearestFlushAlert: nearestFlushAlert)
    }
}
