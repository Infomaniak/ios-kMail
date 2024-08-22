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

import InfomaniakCoreUI
import MailCore
import MailResources
import RealmSwift
import SwiftUI

struct ExternalRecipientView: View {
    @Environment(\.dismiss) private var dismiss

    public var externalTagSate: DisplayExternalRecipientStatus.State
    public var isDraft: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(isDraft ? MailResourcesStrings.Localizable.externalDialogTitleRecipient : MailResourcesStrings.Localizable
                .externalDialogTitleExpeditor)
                .textStyle(.bodyMedium)
                .padding(.bottom, IKPadding.alertTitleBottom)

            switch externalTagSate {
            case .none:
                EmptyView()
            case .one(let recipient):
                Text(isDraft ? MailResourcesStrings.Localizable
                    .externalDialogDescriptionRecipient(recipient.email) : MailResourcesStrings.Localizable
                    .externalDialogDescriptionExpeditor(recipient.email))
                    .textStyle(.bodySecondary)
                    .padding(.bottom, IKPadding.alertDescriptionBottom)
            case .many:
                Text(isDraft ? MailResourcesStrings.Localizable.externalDialogDescriptionRecipientPlural : MailResourcesStrings
                    .Localizable.externalDialogDescriptionExpeditorPlural)
                    .textStyle(.bodySecondary)
                    .padding(.bottom, IKPadding.alertDescriptionBottom)
            }

            ModalButtonsView(
                primaryButtonTitle: MailResourcesStrings.Localizable.externalDialogConfirmButton,
                secondaryButtonTitle: nil
            ) {
                dismiss()
            }
        }
    }
}

#Preview {
    ExternalRecipientView(externalTagSate: .many, isDraft: false)
}
