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

struct ThreadModeSettingUpdate: Identifiable {
    let id = UUID()
    let newSetting: ThreadMode
}

struct SettingsThreadModeView: View {
    @State private var selectedValue: ThreadMode
    @State private var threadModeSettingUpdate: ThreadModeSettingUpdate?

    init() {
        _selectedValue = State(wrappedValue: UserDefaults.shared.threadMode)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            List {
                SettingsSectionTitleView(title: MailResourcesStrings.Localizable.settingsSelectDisplayModeDescription)
                    .settingsCell()

                ForEach(ThreadMode.allCases, id: \.rawValue) { value in
                    SettingsOptionCell(value: value, isSelected: value == selectedValue, isLast: value == ThreadMode.allCases.last) {
                        if value != selectedValue {
                            threadModeSettingUpdate = ThreadModeSettingUpdate(newSetting: value)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .environment(\.defaultMinListRowHeight, 0)
        .background(MailResourcesAsset.backgroundColor.swiftUIColor)
        .navigationBarTitle(MailResourcesStrings.Localizable.settingsThreadModeTitle, displayMode: .inline)
        .customAlert(item: $threadModeSettingUpdate) { threadModeUpdate in
            VStack(alignment: .leading, spacing: 24) {
                Text(MailResourcesStrings.Localizable.settingsThreadModeWarningTitle(threadModeUpdate.newSetting.title))
                    .textStyle(.bodyMedium)
                Text(MailResourcesStrings.Localizable.settingsThreadModeWarningDescription)
                    .textStyle(.bodySecondary)
                ModalButtonsView(
                    primaryButtonTitle: MailResourcesStrings.Localizable.buttonConfirm,
                    secondaryButtonTitle: MailResourcesStrings.Localizable.buttonCancel
                ) {
                    selectedValue = threadModeUpdate.newSetting
                    UserDefaults.shared.threadMode = selectedValue
                }
            }
        }
    }
}

struct SettingsThreadModeView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsThreadModeView()
    }
}
