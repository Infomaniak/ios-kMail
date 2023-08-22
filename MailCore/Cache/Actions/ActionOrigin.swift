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
    public enum ActionOriginType {
        case swipe
        case floatingPanel
        case toolbar
        case multipleSelection
    }

    private(set) var type: ActionOriginType
    private(set) var nearestMessagesActionsPanel: Binding<[Message]?>?
    private(set) var nearestFlushAlert: Binding<FlushAlertState?>?
    private(set) var nearestMessagesToMoveSheet: Binding<[Message]?>?
    private(set) var nearestReportJunkMessageActionsPanel: Binding<Message?>?
    private(set) var nearestReportedForPhishingMessageAlert: Binding<Message?>?
    private(set) var nearestReportedForDisplayProblemMessageAlert: Binding<Message?>?

    public static let toolbar = ActionOrigin(type: .toolbar)

    public static func floatingPanel(nearestMessagesToMoveSheet: Binding<[Message]?>? = nil,
                                     nearestReportJunkMessageActionsPanel: Binding<Message?>? = nil,
                                     nearestReportedForPhishingMessageAlert: Binding<Message?>? = nil,
                                     nearestReportedForDisplayProblemMessageAlert: Binding<Message?>? = nil) -> ActionOrigin {
        return ActionOrigin(
            type: .floatingPanel,
            nearestMessagesToMoveSheet: nearestMessagesToMoveSheet,
            nearestReportJunkMessageActionsPanel: nearestReportJunkMessageActionsPanel,
            nearestReportedForPhishingMessageAlert: nearestReportedForPhishingMessageAlert,
            nearestReportedForDisplayProblemMessageAlert: nearestReportedForDisplayProblemMessageAlert
        )
    }

    public static func multipleSelection(nearestFlushAlert: Binding<FlushAlertState?>? = nil) -> ActionOrigin {
        return ActionOrigin(type: .multipleSelection, nearestFlushAlert: nearestFlushAlert)
    }

    public static func swipe(nearestMessagesActionsPanel: Binding<[Message]?>? = nil, nearestMessagesToMoveSheet: Binding<[Message]?>? = nil) -> ActionOrigin {
        return ActionOrigin(type: .swipe, nearestMessagesActionsPanel: nearestMessagesActionsPanel, nearestMessagesToMoveSheet: nearestMessagesToMoveSheet)
    }
}
