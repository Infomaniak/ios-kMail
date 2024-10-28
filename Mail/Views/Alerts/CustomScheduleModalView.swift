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

import MailResources
import SwiftUI
import InfomaniakCoreSwiftUI

struct CustomScheduleModalView: View {
    @Binding var isFloatingPanelPresented: Bool
    @Binding var selectedDate: Date

    let confirmAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Choisir une date et une heure")
                .textStyle(.bodyMedium)
                .padding(.bottom, IKPadding.alertTitleBottom)
            DatePicker("", selection: $selectedDate, in: .now...)
                .labelsHidden()
            ModalButtonsView(primaryButtonTitle: "Programmer",
                             secondaryButtonTitle: MailResourcesStrings.Localizable.buttonCancel,
                             primaryButtonAction: { confirmAction() },
                             secondaryButtonAction: { isFloatingPanelPresented = true })
        }
    }
}
