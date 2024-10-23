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

struct ScheduleModalView: View {
    @Binding var isFloatingPanelPresented: Bool

    @State private var selectedDate: Date = .now

    var body: some View {
        VStack(spacing: 16) {
            Text("Choisir une date et une heure")
            DatePicker("", selection: $selectedDate)
                .labelsHidden()
            ModalButtonsView(primaryButtonTitle: MailResourcesStrings.Localizable.buttonYes,
                             secondaryButtonTitle: MailResourcesStrings.Localizable.buttonCancel,
                             primaryButtonAction: { print("oui") },
                             secondaryButtonAction: { isFloatingPanelPresented = true })
        }
    }
}
