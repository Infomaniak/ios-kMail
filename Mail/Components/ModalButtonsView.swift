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
    let primaryButtonTitle: String
    let secondaryButtonTitle: String?
    let primaryButtonEnabled: Bool
    let primaryButtonAction: () -> Void
    let secondaryButtonAction: (() -> Void)?

    internal init(primaryButtonTitle: String,
                  secondaryButtonTitle: String? = nil,
                  primaryButtonEnabled: Bool = true,
                  primaryButtonAction: @escaping () -> Void,
                  secondaryButtonAction: (() -> Void)? = nil) {
        self.primaryButtonTitle = primaryButtonTitle
        self.secondaryButtonTitle = secondaryButtonTitle
        self.primaryButtonEnabled = primaryButtonEnabled
        self.primaryButtonAction = primaryButtonAction
        self.secondaryButtonAction = secondaryButtonAction
    }

    var body: some View {
        HStack(spacing: 24) {
            if let secondaryButtonTitle {
                Button(role: .destructive) {
                    secondaryButtonAction?()
                } label: {
                    Text(secondaryButtonTitle)
                        .textStyle(.bodyMediumError)
                }
            }

            ModalButton(label: primaryButtonTitle,
                              isDisabled: !primaryButtonEnabled,
                              action: primaryButtonAction)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

struct BottomSheetButtonsView_Previews: PreviewProvider {
    static var previews: some View {
        ModalButtonsView(primaryButtonTitle: "Save",
                               secondaryButtonTitle: "Cancel",
                               primaryButtonEnabled: false,
                               primaryButtonAction: { /* Preview */ },
                               secondaryButtonAction: { /* Preview */ })
    }
}
