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

struct SettingsSwipeActionsView: View {
    @ObservedObject var viewModel: SwipeActionSettingsViewModel
    @AppStorage(UserDefaults.shared.key(.accentColor)) var accentColor = AccentColor.pink

    init(viewModel: SwipeActionSettingsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        List {
            ForEach(viewModel.sections) { section in
                Section {
                    ForEach(section.items) { item in
                        if case let .option(option) = item.type {
                            SettingsOptionCell(
                                icon: icon(for: option),
                                title: item.title,
                                subtitle: viewModel.selectedValues[option]?.title ?? "",
                                option: option
                            )
                            .frame(minHeight: 40)
                            .padding(.horizontal, 8)
                        }
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        SwipeConfigCell(selectedValues: $viewModel.selectedValues, section: section)
                        if section != viewModel.sections.last {
                            IKDivider()
                        }
                    }
                } header: {
                    if section == viewModel.sections.first {
                        Text(MailResourcesStrings.Localizable.settingsSwipeDescription)
                            .textStyle(.calloutSecondary)
                            .padding(.horizontal, 8)
                    }
                }
                .listSectionSeparator(.hidden)
                .listRowSeparator(.hidden)
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

    private func icon(for option: SettingsOption) -> Image? {
        let resource: MailResourcesImages?
        switch option {
        case .swipeShortRightOption:
            resource = accentColor.shortRightIcon
        case .swipeLongRightOption:
            resource = accentColor.longRightIcon
        case .swipeShortLeftOption:
            resource = accentColor.shortLeftIcon
        case .swipeLongLeftOption:
            resource = accentColor.longLeftIcon
        default:
            resource = nil
        }
        if let resource = resource {
            return Image(resource: resource)
        } else {
            return nil
        }
    }
}

struct SettingsSwipeActionsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsSwipeActionsView(viewModel: SwipeActionSettingsViewModel())
    }
}
