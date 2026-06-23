/*
 Infomaniak Mail - iOS App
 Copyright (C) 2025 Infomaniak Network SA

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
import MailResources
import SwiftUI

struct CustomReminderAlertView: View {
    private enum Constants {
        static let pickerHeight: CGFloat = 120
    }

    @State private var selectedUnit: ReminderOption.CustomUnit
    @State private var selectedValue: Int

    let confirmAction: (ReminderOption) -> Void
    let cancelAction: (() -> Void)?

    init(
        unit: ReminderOption.CustomUnit = .hours,
        value: Int = 1,
        confirmAction: @escaping (ReminderOption) -> Void,
        cancelAction: (() -> Void)? = nil
    ) {
        _selectedUnit = State(initialValue: unit)
        _selectedValue = State(initialValue: min(max(value, unit.range.lowerBound), unit.range.upperBound))
        self.confirmAction = confirmAction
        self.cancelAction = cancelAction
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(MailResourcesStrings.Localizable.buttonCustomSchedule)
                .textStyle(.bodyMedium)
                .padding(.bottom, IKPadding.alertTitleBottom)

            HStack(spacing: IKPadding.micro) {
                Picker("", selection: $selectedValue) {
                    ForEach(selectedUnit.range, id: \.self) { value in
                        Text("\(value)").tag(value)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()

                Picker("", selection: $selectedUnit) {
                    ForEach(ReminderOption.CustomUnit.allCases, id: \.self) { unit in
                        Text(unit.title).tag(unit)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()
            }
            .frame(height: Constants.pickerHeight)
            .onChange(of: selectedUnit) { newUnit in
                selectedValue = min(max(selectedValue, newUnit.range.lowerBound), newUnit.range.upperBound)
            }

            ModalButtonsView(
                primaryButtonTitle: MailResourcesStrings.Localizable.buttonConfirm,
                secondaryButtonTitle: MailResourcesStrings.Localizable.buttonCancel,
                primaryButtonAction: { confirmAction(selectedUnit.makeOption(value: selectedValue)) },
                secondaryButtonAction: cancelAction
            )
        }
    }
}

#Preview {
    CustomReminderAlertView { option in
        print("Selected: \(option)")
    }
}
