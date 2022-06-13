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
import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

//    let sections: [SettingsSection] = [.emailAddresses, .general, .appearance]
    @State var selectedValues: [SettingsOption: SettingsOptionEnum] = [:]

    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        List {
            ForEach(viewModel.sections) { section in
                Section(header: Text(section.name)) {
                    ForEach(section.items) { item in
                        switch item.type {
                        case let .subMenu(destination: destination):
                            SettingsSubMenuCell(title: item.title, destination: destination)
                        case let .toggle(userDefaults: userDefaults):
                            SettingsToggleCell(title: item.title, userDefaults: userDefaults)
                        case let .option(option):
                            SettingsOptionCell(title: item.title, subtitle: selectedValues[option]?.title ?? "", option: option)
                        }
                    }
                }
            }
        }
        .navigationBarTitle("Settings")
        .onAppear {
            updateSelectedValues()
        }
    }

    private func updateSelectedValues() {
        selectedValues = [
            .themeOption: UserDefaults.shared.theme
        ]
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(viewModel: GeneralSettingsViewModel())
    }
}
