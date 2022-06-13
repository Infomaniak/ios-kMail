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

import Foundation
import MailCore
import MailResources
import Network
import SwiftUI

@MainActor class GeneralSettingsViewModel: SettingsViewModel {
    init() {
        super.init(title: MailResourcesStrings.settingsTitle)
        sections = [.emailAddresses, .general, .appearance]
    }
}

private extension SettingsSection {
    static let emailAddresses = SettingsSection(
        id: 1,
        name: "Adresses mail",
        items: []
    )
    static let general = SettingsSection(
        id: 2,
        name: "Général",
        items: [.send, .lock]
    )
    static let appearance = SettingsSection(
        id: 3,
        name: "Apparence",
        items: [.threadDensity, .theme, .swipeActions, .displayMode, .externalContent]
    )
}

private extension SettingsItem {
    static let send = SettingsItem(id: 1, title: "Envoi", type: .subMenu(destination: .send))
    static let lock = SettingsItem(id: 2, title: "Verrouillage par code", type: .toggle(userDefaults: \.isAppLockEnabled))
    static let threadDensity = SettingsItem(id: 3, title: "Densité de la liste des conversations", type: .option(.threadDensityOption))
    static let theme = SettingsItem(id: 4, title: "Thème", type: .option(.themeOption))
    static let swipeActions = SettingsItem(id: 5, title: "Actions de balayage dans la messagerie", type: .subMenu(destination: .swipe))
    static let displayMode = SettingsItem(id: 6, title: "Mode d’affichage des messages", type: .option(.displayModeOption))
    static let externalContent = SettingsItem(id: 7, title: "Afficher le contenu externe", type: .option(.externalContentOption))
}

