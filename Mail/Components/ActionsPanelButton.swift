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

import CocoaLumberjackSwift
import MailCore
import MailResources
import SwiftUI

struct ActionsPanelButton<Content: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    @State private var actionsTarget: ActionsTarget?

    var message: Message?
    var threads: [Thread]?
    var isMultiSelectionEnabled = false
    @ViewBuilder var label: () -> Content

    var isCompact: Bool {
        horizontalSizeClass == .compact || verticalSizeClass == .compact
    }

    var body: some View {
        if isCompact {
            buttonBody
                .actionsPanel(actionsTarget: $actionsTarget)
        } else {
            buttonBody
                .actionsPopOver(actionsTarget: $actionsTarget)
        }
    }

    var buttonBody: some View {
        Button {
            if let message {
                actionsTarget = .message(message)
            } else if let threads {
                actionsTarget = .threads(threads, isMultiSelectionEnabled)
            } else {
                DDLogWarn("MoreButton has no action target, did you forget to set message or threads ?")
            }
        } label: {
            label()
        }
    }
}
