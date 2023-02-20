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

import MailCore
import MailResources
import SwiftUI

struct FlushFolderAlertView: View {
    @StateObject var flushAlert: FlushAlertState

    var folder: Folder?
    let confirmHandler: () -> Void

    var title: String {
        if let deletedMessagesCount = flushAlert.deletedMessages {
            return MailResourcesStrings.Localizable.threadListFlushFolderAlertTitle(deletedMessagesCount)
        }

        switch folder?.role {
        case .trash:
            return MailResourcesStrings.Localizable.threadListTrashEmptyButton
        case .spam:
            return MailResourcesStrings.Localizable.threadListSpamEmptyButton
        default:
            return ""
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(title)
                .textStyle(.bodyMedium)

            Text(MailResourcesStrings.Localizable.threadListFlushFolderAlertDescription)
                .textStyle(.body)

            BottomSheetButtonsView(primaryButtonTitle: MailResourcesStrings.Localizable.buttonConfirm,
                                   secondaryButtonTitle: MailResourcesStrings.Localizable.buttonClose) {
                flushAlert.completion?()
                flushAlert.isShowing = false
            } secondaryButtonAction: {
                flushAlert.isShowing = false
            }
        }
    }
}

struct FlushFolderAlertView_Previews: PreviewProvider {
    static var previews: some View {
        FlushFolderAlertView(flushAlert: FlushAlertState()) { /* Preview */ }
    }
}
