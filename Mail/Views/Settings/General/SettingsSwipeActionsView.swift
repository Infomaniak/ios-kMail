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
    case rightSwipe
    case leftSwipe

    var items: [SwipeType] {
        switch self {
        case .rightSwipe:
            return [.shortRight, .longRight]
        case .leftSwipe:
            return [.shortLeft, .longLeft]
        }
    }
}

struct SettingsSwipeActionsView: View {
    @AppStorage(UserDefaults.shared.key(.accentColor)) var accentColor = AccentColor.pink

    @AppStorage(UserDefaults.shared.key(.swipeShortRight)) var shortRight = SwipeAction.none
    @AppStorage(UserDefaults.shared.key(.swipeLongRight)) var longRight = SwipeAction.none
    @AppStorage(UserDefaults.shared.key(.swipeShortLeft)) var shortLeft = SwipeAction.none
    @AppStorage(UserDefaults.shared.key(.swipeLongLeft)) var longLeft = SwipeAction.none

    var body: some View {
        List {
            ForEach(SwipeSettingsSection.allCases, id: \.self) { section in
                Section {
                    ForEach(section.items, id: \.self) { item in
                        SettingsOptionCell(title: item.title, subtitle: settingValue(for: item), icon: icon(for: item)) {
                            SettingsOptionView<SwipeAction>(
                                title: item.title,
                                keyPath: item.keyPath,
                                excludedKeyPath: [\.swipeLongRight]
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
        case .shortRight:
            return shortRight.title
        case .longRight:
            return longRight.title
        case .shortLeft:
            return shortLeft.title
        case .longLeft:
            return longLeft.title
        }
    }

    private func icon(for option: SwipeType) -> Image {
        let resource: MailResourcesImages
        switch option {
        case .shortRight:
            resource = accentColor.shortRightIcon
        case .longRight:
            resource = accentColor.longRightIcon
        case .shortLeft:
            resource = accentColor.shortLeftIcon
        case .longLeft:
            resource = accentColor.longLeftIcon
        }
        return Image(resource: resource)
    }
}

struct SettingsSwipeActionsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsSwipeActionsView()
    }
}
