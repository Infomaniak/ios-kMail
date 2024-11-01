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
import MailResources
import SwiftUI

struct CustomScheduleModalView: View {
    @Binding var isFloatingPanelPresented: Bool
    @Binding var selectedDate: Date

    let confirmAction: (Date) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(MailResourcesStrings.Localizable.datePickerTitle)
                .textStyle(.bodyMedium)
                .padding(.bottom, IKPadding.alertTitleBottom)
            DatePicker("", selection: $selectedDate, in: .now...)
                .labelsHidden()
                .padding(.bottom, IKPadding.alertDescriptionBottom)
            ModalButtonsView(primaryButtonTitle: MailResourcesStrings.Localizable.buttonScheduleTitle,
                             secondaryButtonTitle: MailResourcesStrings.Localizable.buttonCancel,
                             primaryButtonAction: { confirmAction(selectedDate) },
                             secondaryButtonAction: { isFloatingPanelPresented = true })
        }
    }
}
