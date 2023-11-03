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

import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailResources
import SwiftUI

struct FlushFolderAlertView: View {
    @LazyInjectService private var matomo: MatomoUtils

    let flushAlert: FlushAlertState
    var folder: Folder?

    private var title: String {
        if let deletedMessagesCount = flushAlert.deletedMessages {
            return MailResourcesStrings.Localizable.threadListDeletionConfirmationAlertTitle(deletedMessagesCount)
        }

        switch folder?.role {
        case .spam:
            return MailResourcesStrings.Localizable.threadListEmptySpamButton
        case .trash:
            return MailResourcesStrings.Localizable.threadListEmptyTrashButton
        default:
            return ""
        }
    }

    private var description: String {
        if let deletedMessagesCount = flushAlert.deletedMessages {
            return MailResourcesStrings.Localizable.threadListDeletionConfirmationAlertDescription(deletedMessagesCount)
        }
        return MailResourcesStrings.Localizable.threadListEmptyFolderAlertDescription
    }

    var body: some View {
        VStack(alignment: .leading, spacing: UIPadding.medium) {
            Text(title)
                .textStyle(.bodyMedium)
            Text(description)
                .textStyle(.body)

            ModalButtonsView(primaryButtonTitle: MailResourcesStrings.Localizable.buttonConfirm) {
                if let folder, flushAlert.deletedMessages == nil {
                    matomo.track(eventWithCategory: .threadList, name: "empty\(folder.matomoName.capitalized)Confirm")
                }
                await flushAlert.completion()
            }
        }
    }
}

struct FlushFolderAlertView_Previews: PreviewProvider {
    static var previews: some View {
        FlushFolderAlertView(flushAlert: FlushAlertState { /* Preview */ })
    }
}
