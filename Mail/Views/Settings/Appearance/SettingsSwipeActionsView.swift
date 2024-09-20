/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

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

import InfomaniakCore
import InfomaniakCoreCommonUI
import MailCore
import MailCoreUI
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
    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor

    @AppStorage(UserDefaults.shared.key(.swipeLeading)) private var leading = DefaultPreferences.swipeLeading
    @AppStorage(UserDefaults.shared.key(.swipeFullLeading)) private var fullLeading = DefaultPreferences.swipeFullLeading
    @AppStorage(UserDefaults.shared.key(.swipeTrailing)) private var trailing = DefaultPreferences.swipeTrailing
    @AppStorage(UserDefaults.shared.key(.swipeFullTrailing)) private var fullTrailing = DefaultPreferences.swipeFullTrailing

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                SettingsSectionTitleView(title: MailResourcesStrings.Localizable.settingsSwipeDescription)

                ForEach(SwipeSettingsSection.allCases, id: \.self) { section in
                    ForEach(section.items, id: \.self) { item in
                        SettingsSubMenuCell(title: item.title, subtitle: settingValue(for: item), icon: icon(for: item)) {
                            SettingsOptionView<Action>(
                                title: item.title,
                                values: Action.swipeActions,
                                keyPath: item.keyPath,
                                excludedKeyPath: item.excludedKeyPaths,
                                matomoCategory: .settingsSwipeActions,
                                matomoName: \.matomoName,
                                matomoValue: item == .leading || item == .fullLeading ? 1 : 0
                            )
                            .frame(minHeight: 40)
                        }
                    }

                    SwipeConfigCell(section: section)

                    if section != SwipeSettingsSection.allCases.last {
                        IKDivider()
                    }
                }
            }
        }
        .background(MailResourcesAsset.backgroundColor.swiftUIColor)
        .navigationBarTitle(MailResourcesStrings.Localizable.settingsSwipeActionsTitle, displayMode: .inline)
        .matomoView(view: [MatomoUtils.View.settingsView.displayName, "SwipeActions"])
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
        return resource.swiftUIImage
    }
}

#Preview {
    SettingsSwipeActionsView()
}
