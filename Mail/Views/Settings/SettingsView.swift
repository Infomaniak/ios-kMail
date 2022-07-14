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

import Introspect
import MailCore
import MailResources
import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        List {
            ForEach(viewModel.sections) { section in
                Section {
                    // Header & separator
                    if section.name != nil || section != viewModel.sections.first {
                        VStack(alignment: .leading, spacing: 24) {
                            if section != viewModel.sections.first {
                                IKDivider()
                            }
                            if let title = section.name {
                                Text(title)
                                    .textStyle(.calloutSecondary)
                                    .padding(.horizontal, 8)
                            }
                        }
                        .listRowSeparator(.hidden)
                        .listRowInsets(.init(top: 12, leading: 8, bottom: 4, trailing: 8))
                    }

                    ForEach(section.items) { item in
                        getSettingView(item: item)
                    }
                    .listRowSeparator(.hidden)
                    .listRowInsets(.init(top: 12, leading: 24, bottom: 12, trailing: 24))
                }
                .listSectionSeparator(.hidden)
                .listRowBackground(MailResourcesAsset.backgroundColor.swiftUiColor)
            }
        }
        .listStyle(.plain)
        .background(MailResourcesAsset.backgroundColor.swiftUiColor)
        .navigationBarTitle(viewModel.title, displayMode: .inline)
        .backButtonDisplayMode(.minimal)
        .onAppear {
            viewModel.updateSelectedValue()
        }
    }

    @ViewBuilder
    private func getSettingView(item: SettingsItem) -> some View {
        switch item.type {
        case let .subMenu(destination: destination):
            SettingsSubMenuCell(title: item.title, destination: destination)
        case let .toggle(userDefaults: userDefaults):
            SettingsToggleCell(title: item.title, userDefaults: userDefaults)
        case let .toggleBinding(keyPath: keyPath):
            SettingsToggleBindingCell(
                title: item.title,
                keyPath: keyPath,
                viewModel: viewModel as! EmailAddressSettingsViewModel
            )
        case let .option(option):
            SettingsOptionCell(
                title: item.title,
                subtitle: viewModel.selectedValues[option]?.title ?? "",
                option: option
            )
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(viewModel: GeneralSettingsViewModel())
    }
}
