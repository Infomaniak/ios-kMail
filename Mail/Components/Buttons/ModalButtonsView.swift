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

struct ModalButtonsView: View {
    @Environment(\.dismiss) private var dismiss

    @State var isButtonLoading = false

    let primaryButtonTitle: String
    var secondaryButtonTitle: String? = MailResourcesStrings.Localizable.buttonCancel
    var primaryButtonEnabled = true
    let primaryButtonAction: () async -> Void
    var secondaryButtonAction: (() -> Void)?

    var body: some View {
        HStack(spacing: UIPadding.medium) {
            if let secondaryButtonTitle {
                MailButton(label: secondaryButtonTitle) {
                    secondaryButtonAction?()
                    dismiss()
                }
                .mailButtonStyle(.link)
            }

            MailButton(label: primaryButtonTitle) {
                Task {
                    isButtonLoading = true
                    await primaryButtonAction()
                    isButtonLoading = false
                    dismiss()
                }
            }
            .disabled(!primaryButtonEnabled)
            .mailButtonLoading(isButtonLoading)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

struct ModalButtonsView_Previews: PreviewProvider {
    static var previews: some View {
        ModalButtonsView(primaryButtonTitle: "Save") { /* Preview */ }
    }
}
