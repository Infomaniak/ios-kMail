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
    var title: String {
        switch type {
        case .flushFolder(let frozenFolder):
            switch frozenFolder?.role {
            case .spam:
                return MailResourcesStrings.Localizable.threadListEmptySpamButton
            case .trash:
                return MailResourcesStrings.Localizable.threadListEmptyTrashButton
            default:
                return ""
            }

        case .permanentlyDelete(let impactedMessages):
            return MailResourcesStrings.Localizable.threadListDeletionConfirmationAlertTitle(impactedMessages)

        case .deleteSnooze:
            return MailResourcesStrings.Localizable.actionDelete

        case .archiveSnooze:
            return MailResourcesStrings.Localizable.actionArchive

        case .moveSnooze:
            return MailResourcesStrings.Localizable.actionMove

        case .deleteFolder:
            return MailResourcesStrings.Localizable.deleteFolderDialogTitle
        }
    }

    var description: AttributedString {
        switch type {
        case .flushFolder:
            return AttributedString(MailResourcesStrings.Localizable.threadListEmptyFolderAlertDescription)

        case .permanentlyDelete(let impactedMessages):
            return AttributedString(MailResourcesStrings.Localizable
                .threadListDeletionConfirmationAlertDescription(impactedMessages))

        case .deleteSnooze(let impactedMessages):
            return AttributedString(MailResourcesStrings.Localizable.snoozeDeleteConfirmAlertDescription(impactedMessages))

        case .archiveSnooze(let impactedMessages):
            return AttributedString(MailResourcesStrings.Localizable.snoozeArchiveConfirmAlertDescription(impactedMessages))

        case .moveSnooze(let impactedMessages):
            return AttributedString(MailResourcesStrings.Localizable.snoozeMoveConfirmAlertDescription(impactedMessages))

        case .deleteFolder(let folder):
            var attributedDescription = AttributedString(MailResourcesStrings.Localizable
                .deleteFolderDialogDescription(folder.name))
            if let range = attributedDescription.range(of: folder.name) {
                attributedDescription[range].font = MailTextStyle.bodyMedium.font
            }
            return attributedDescription
        }
    }
}

struct DestructiveActionAlertView: View {
    let destructiveAlert: DestructiveActionAlertState

    var body: some View {
        VStack(alignment: .leading, spacing: IKPadding.large) {
            Text(destructiveAlert.title)
                .textStyle(.bodyMedium)

            Text(destructiveAlert.description)
                .multilineTextAlignment(.leading)
                .textStyle(.body)

            ModalButtonsView(primaryButtonTitle: MailResourcesStrings.Localizable.buttonConfirm) {
                if case .flushFolder(let frozenFolder) = destructiveAlert.type, let frozenFolder {
                    @InjectService var matomo: MatomoUtils
                    matomo.track(eventWithCategory: .threadList, name: "empty\(frozenFolder.matomoName.capitalized)Confirm")
                }
                await destructiveAlert.completion()
            }
        }
    }
}

#Preview {
    DestructiveActionAlertView(destructiveAlert: DestructiveActionAlertState(type: .deleteSnooze(10)) { /* Preview */ })
}
