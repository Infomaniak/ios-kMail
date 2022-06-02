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
import UIKit

class ThemeSettingViewModel: SettingsSelectionViewModel {
    private var content: [Theme] = [.system, .light, .dark]

    init() {
        super.init(
            title: MailResourcesStrings.settingsThemeChoiceTitle,
            header: MailResourcesStrings.settingsTheme
        )

        for (indice, theme) in content.enumerated() {
            tableContent.append(
                SettingsSelectionContent(
                    id: indice,
                    view: AnyView(SettingsSelectionCellView(title: theme.title, image: theme.icon)),
                    isSelected: theme == UserDefaults.shared.theme
                )
            )
        }
    }

    override func updateSelection(newValue: Int) {
        super.updateSelection(newValue: newValue)
        UserDefaults.shared.theme = content[newValue]

        // TODO: - clean this
        (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.window?
            .overrideUserInterfaceStyle = content[newValue].interfaceStyle
    }
}
