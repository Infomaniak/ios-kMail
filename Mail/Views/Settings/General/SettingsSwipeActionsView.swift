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

enum SwipeSettingsSection: CaseIterable {
    case leadingSwipe
    case trailingSwipe

    var items: [SwipeType] {
        switch self {
        case .leadingSwipe:
            return [.leading, .fullLeading]
        case .trailingSwipe:
            return [.trailing, .fullTrailing]
        }
    }
}

struct SettingsSwipeActionsView: View {
    @AppStorage(UserDefaults.shared.key(.accentColor)) var accentColor = DefaultPreferences.accentColor

    @AppStorage(UserDefaults.shared.key(.swipeLeading)) var leading = DefaultPreferences.swipeLeading
    @AppStorage(UserDefaults.shared.key(.swipeFullLeading)) var fullLeading = DefaultPreferences.swipeFullLeading
    @AppStorage(UserDefaults.shared.key(.swipeTrailing)) var trailing = DefaultPreferences.swipeTrailing
    @AppStorage(UserDefaults.shared.key(.swipeFullTrailing)) var fullTrailing = DefaultPreferences.swipeFullTrailing

    var body: some View {
        List {
            ForEach(SwipeSettingsSection.allCases, id: \.self) { section in
                Section {
                    ForEach(section.items, id: \.self) { item in
                        SettingsSubMenuCell(title: item.title, subtitle: settingValue(for: item), icon: icon(for: item)) {
                            SettingsOptionView<SwipeAction>(
                                title: item.title,
                                values: SwipeAction.allCases.filter(\.isCustomizable),
                                keyPath: item.keyPath,
                                excludedKeyPath: [\.swipeFullLeading]
                            )
                            .frame(minHeight: 40)
                            .padding(.horizontal, 8)
                        }
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        SwipeConfigCell(section: section)
                        if section != SwipeSettingsSection.allCases.last {
                            IKDivider()
                        }
                    }
                } header: {
                    if section == SwipeSettingsSection.allCases.first {
                        Text(MailResourcesStrings.Localizable.settingsSwipeDescription)
                            .textStyle(.bodySmallSecondary)
                            .padding(.horizontal, 8)
                    }
                }
                .listSectionSeparator(.hidden)
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .background(MailResourcesAsset.backgroundColor.swiftUiColor)
        .navigationBarTitle(MailResourcesStrings.Localizable.settingsSwipeActionsTitle, displayMode: .inline)
        .backButtonDisplayMode(.minimal)
    }

    private func settingValue(for option: SwipeType) -> String {
        switch option {
        case .leading:
            return leading.title
        case .fullLeading:
            return fullLeading.title
        case .trailing:
            return trailing.title
        case .fullTrailing:
            return fullTrailing.title
        }
    }

    private func icon(for option: SwipeType) -> Image {
        let resource: MailResourcesImages
        switch option {
        case .leading:
            resource = accentColor.leadingIcon
        case .fullLeading:
            resource = accentColor.fullLeadingIcon
        case .trailing:
            resource = accentColor.trailingIcon
        case .fullTrailing:
            resource = accentColor.fullTrailingIcon
        }
        return Image(resource: resource)
    }
}

struct SettingsSwipeActionsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsSwipeActionsView()
    }
}
