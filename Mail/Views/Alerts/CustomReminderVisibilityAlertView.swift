/*
 Infomaniak Mail - iOS App
 Copyright (C) 2026 Infomaniak Network SA

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
import InfomaniakCoreSwiftUI
import MailCore
import MailCoreUI
import MailResources
import SwiftUI

struct CustomReminderVisibilityAlertView: View {
    private enum Constants {
        static let contentHeight: CGFloat = 120
    }

    @State private var selectedVisibility: ReminderVisibility = .recipientsAndMe

    let confirmAction: (ReminderVisibility) -> Void
    let cancelAction: (() -> Void)?

    init(
        currentVisibility: ReminderVisibility? = .recipientsAndMe,
        confirmAction: @escaping (ReminderVisibility) -> Void,
        cancelAction: (() -> Void)? = nil
    ) {
        if let visibility = currentVisibility {
            selectedVisibility = visibility
        } else {
            selectedVisibility = .recipientsAndMe
        }

        self.confirmAction = confirmAction
        self.cancelAction = cancelAction
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(MailResourcesStrings.Localizable.selectionReminderTitle)
                .textStyle(.bodyMedium)
                .padding(.bottom, IKPadding.alertTitleBottom)

            VStack(alignment: .leading) {
                ForEach(ReminderVisibility.allCases, id: \.self) { visibility in
                    ReminderVisibilityCell(visibility: visibility, isSelected: selectedVisibility == visibility, isInModal: true) {
                        selectedVisibility = visibility
                    }
                    if ReminderVisibility.allCases.last != visibility {
                        IKDivider(type: .item)
                    }
                }
            }
            .frame(height: Constants.contentHeight)

            ModalButtonsView(
                primaryButtonTitle: MailResourcesStrings.Localizable.buttonConfirm,
                secondaryButtonTitle: MailResourcesStrings.Localizable.buttonCancel,
                primaryButtonAction: { confirmAction(selectedVisibility) },
                secondaryButtonAction: cancelAction
            )
        }
    }
}

#Preview {
    CustomReminderVisibilityAlertView { visibility in
        print("Selected: \(visibility)")
    }
}
