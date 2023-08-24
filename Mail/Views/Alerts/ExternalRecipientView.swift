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
import RealmSwift
import SwiftUI

struct ExternalRecipientView: View {
    @Environment(\.dismiss) private var dismiss

    @State public var externalTagSate: DisplayExternalRecipientStatus.State

    public var isDraft: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            
            isDraft ? Text(MailResourcesStrings.Localizable.externalDialogTitleRecipient)
                .textStyle(.bodyMedium) : Text(MailResourcesStrings.Localizable.externalDialogTitleExpeditor)
                .textStyle(.bodyMedium)

            switch externalTagSate {
            case .none:
                EmptyView()
            case .one(let recipient):
                isDraft ? Text(MailResourcesStrings.Localizable.externalDialogDescriptionRecipient(recipient.email))
                    .textStyle(.bodySecondary) : Text(MailResourcesStrings.Localizable.externalDialogDescriptionExpeditor(recipient.email))
                    .textStyle(.bodySecondary)
            case .many:
                isDraft ? Text(MailResourcesStrings.Localizable.externalDialogDescriptionRecipientPlural)
                    .textStyle(.bodySecondary) : Text(MailResourcesStrings.Localizable.externalDialogDescriptionExpeditorPlural)
                    .textStyle(.bodySecondary)
            }

            ModalButtonsView(primaryButtonTitle: MailResourcesStrings.Localizable.externalDialogConfirmButton, secondaryButtonTitle: nil) {
                dismiss()
            }
        }
    }
}

struct ExternalRecipientView_Previews: PreviewProvider {
    static var previews: some View {
        ExternalRecipientView(externalTagSate: .many, isDraft: false)
    }
}
