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
import SwiftUI

struct SettingsSelectionContent: Identifiable {
    var id: Int
    let view: AnyView
    var isSelected: Bool
}

@MainActor class SettingsSelectionViewModel: ObservableObject {
    @Published public var tableContent: [SettingsSelectionContent] = []

    public var title: String
    public var header: String?

    init(title: String, header: String? = nil) {
        self.title = title
        self.header = header
    }

    public func updateSelection(newValue: Int) {
        if let oldIndex = tableContent.firstIndex(where: { $0.isSelected == true }) {
            tableContent[oldIndex].isSelected = false
        }
        tableContent[newValue].isSelected = true
    }
}
