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

import MailResources
import SwiftUI
import UIKit

//@MainActor class MessageDisplayModeSettingViewModel: SettingsSelectionViewModel {
//    private var content: [(title: String, image: UIImage, value: Bool)] = [
//        (title: MailResourcesStrings.settingsOptionDiscussions, image: MailResourcesAsset.conversationEmail.image, value: true),
//        (title: MailResourcesStrings.settingsOptionMessages, image: MailResourcesAsset.singleEmail.image, value: false)
//    ]
//
//    init() {
//        super.init(
//            title: MailResourcesStrings.settingsMessageDisplayTitle,
//            header: MailResourcesStrings.settingsSelectDisplayModeDescription
//        )
//
//        for (indice, display) in content.enumerated() {
//            tableContent.append(
//                SettingsSelectionContent(
//                    id: indice,
//                    view: AnyView(SettingsSelectionCellView(title: display.title, image: Image(uiImage: display.image))),
//                    isSelected: display.value == UserDefaults.shared.threadMode
//                )
//            )
//        }
//    }
//
//    override func updateSelection(newValue: Int) {
//        super.updateSelection(newValue: newValue)
//        UserDefaults.shared.threadMode = content[newValue].value
//    }
//}
