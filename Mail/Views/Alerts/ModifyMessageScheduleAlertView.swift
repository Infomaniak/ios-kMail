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

import InfomaniakCoreSwiftUI
import MailCore
import MailResources
import SwiftUI

struct ModifyMessageScheduleAlertView: View {
    @EnvironmentObject private var mainViewState: MainViewState
    @EnvironmentObject private var mailboxManager: MailboxManager

    let draftResource: String

    var body: some View {
        VStack(alignment: .leading, spacing: IKPadding.medium) {
            Text(MailResourcesStrings.Localizable.editSendTitle)
                .textStyle(.bodyMedium)
            Text(MailResourcesStrings.Localizable.editSendDescription)
                .textStyle(.body)
            ModalButtonsView(primaryButtonTitle: MailResourcesStrings.Localizable.buttonModify,
                             secondaryButtonTitle: MailResourcesStrings.Localizable.buttonCancel,
                             primaryButtonAction: modifySchedule)
        }
    }

    private func modifySchedule() {
        Task {
            await tryOrDisplayError {
                try await mailboxManager.moveScheduleToDraft(draftResource: draftResource)
                guard let draft = try await mailboxManager.loadRemotely(from: draftResource) else { return }

                DraftUtils.editDraft(
                    from: draft,
                    mailboxManager: mailboxManager,
                    composeMessageIntent: $mainViewState.composeMessageIntent
                )
            }
        }
    }
}

#Preview {
    ModifyMessageScheduleAlertView(draftResource: "")
}
