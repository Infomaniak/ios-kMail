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

import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailResources
import SwiftUI

struct FlushFolderAlertView: View {
    @LazyInjectService private var matomo: MatomoUtils

    let flushAlert: FlushAlertState
    var frozenFolder: Folder?

    init(flushAlert: FlushAlertState, folder: Folder? = nil) {
        self.flushAlert = flushAlert
        frozenFolder = folder?.freezeIfNeeded()
    }

    private var title: String {
        if let deletedMessagesCount = flushAlert.deletedMessages {
            return MailResourcesStrings.Localizable.threadListDeletionConfirmationAlertTitle(deletedMessagesCount)
        }

        switch frozenFolder?.role {
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
        VStack(alignment: .leading, spacing: IKPadding.large) {
            Text(title)
                .textStyle(.bodyMedium)
            Text(description)
                .textStyle(.body)

            ModalButtonsView(primaryButtonTitle: MailResourcesStrings.Localizable.buttonConfirm) {
                if let frozenFolder, flushAlert.deletedMessages == nil {
                    matomo.track(eventWithCategory: .threadList, name: "empty\(frozenFolder.matomoName.capitalized)Confirm")
                }
                await flushAlert.completion()
            }
        }
    }
}

#Preview {
    FlushFolderAlertView(flushAlert: FlushAlertState { /* Preview */ })
}
