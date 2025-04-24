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
import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailResources
import SwiftUI

extension DestructiveActionAlertState {
    func title(in folder: Folder?) -> String {
        switch type {
        case .delete:
            if let impactedMessages {
                return MailResourcesStrings.Localizable.threadListDeletionConfirmationAlertTitle(impactedMessages)
            } else {
                switch folder?.role {
                case .spam:
                    return MailResourcesStrings.Localizable.threadListEmptySpamButton
                case .trash:
                    return MailResourcesStrings.Localizable.threadListEmptyTrashButton
                default:
                    return ""
                }
            }

        case .deleteSnooze:
            return "!TODO"

        case .archiveSnooze:
            return "!TODO"

        case .moveSnooze:
            return "!TODO"
        }
    }

    var description: String {
        switch type {
        case .delete:
            if let impactedMessages {
                return MailResourcesStrings.Localizable.threadListDeletionConfirmationAlertDescription(impactedMessages)
            } else {
                return MailResourcesStrings.Localizable.threadListEmptyFolderAlertDescription
            }

        case .deleteSnooze:
            return "!TODO"

        case .archiveSnooze:
            return "!TODO"

        case .moveSnooze:
            return "!TODO"
        }
    }
}

struct DestructiveActionAlertView: View {
    @LazyInjectService private var matomo: MatomoUtils

    let destructiveAlert: DestructiveActionAlertState
    var frozenFolder: Folder?

    init(destructiveAlert: DestructiveActionAlertState, folder: Folder? = nil) {
        self.destructiveAlert = destructiveAlert
        frozenFolder = folder?.freezeIfNeeded()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: IKPadding.large) {
            Text(destructiveAlert.title(in: frozenFolder))
                .textStyle(.bodyMedium)
            Text(destructiveAlert.description)
                .textStyle(.body)

            ModalButtonsView(primaryButtonTitle: MailResourcesStrings.Localizable.buttonConfirm) {
                if let frozenFolder, destructiveAlert.impactedMessages == nil {
                    matomo.track(eventWithCategory: .threadList, name: "empty\(frozenFolder.matomoName.capitalized)Confirm")
                }
                await destructiveAlert.completion()
            }
        }
    }
}

#Preview {
    DestructiveActionAlertView(destructiveAlert: DestructiveActionAlertState(type: .delete) { /* Preview */ })
}
