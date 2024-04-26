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
        HStack(spacing: UIPadding.verySmall) {
            if let secondaryButtonTitle {
                Button(secondaryButtonTitle) {
                    secondaryButtonAction?()
                    dismiss()
                }
                .buttonStyle(.ikLink())
            }

            Button(primaryButtonTitle) {
                Task {
                    isButtonLoading = true
                    await primaryButtonAction()
                    isButtonLoading = false
                    dismiss()
                }
            }
            .buttonStyle(.ikPlain)
            .disabled(!primaryButtonEnabled)
            .ikButtonLoading(isButtonLoading)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

#Preview {
    ModalButtonsView(primaryButtonTitle: "Save") { /* Preview */ }
}
