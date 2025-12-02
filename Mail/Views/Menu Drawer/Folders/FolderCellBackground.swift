/*
 Infomaniak Mail - iOS App
 Copyright (C) 2025 Infomaniak Network SA

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


import DesignSystem
import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import SwiftModalPresentation
import SwiftUI

struct FolderCellBackground: View {
    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor
    @Environment(\.isHovered) private var isHovered
    @Environment(\.folderCellType) private var cellType

    let isCurrentFolder: Bool

    var body: some View {
        if cellType == .menuDrawer {
            SelectionBackground(
                selectionType: (isCurrentFolder || isHovered) ? .folder : .none,
                paddingLeading: 0,
                accentColor: accentColor
            )
            .background(RoundedRectangle(cornerRadius: IKRadius.medium)
                .fill(MailResourcesAsset.backgroundSecondaryColor.swiftUIColor))
        }
    }
}
