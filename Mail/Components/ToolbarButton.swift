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

struct ToolbarButton: View {
    @Environment(\.verticalSizeClass) private var sizeClass

    let text: String
    let icon: MailResourcesImages
    let width: CGFloat?
    let action: () -> Void

    init(text: String, icon: MailResourcesImages, width: CGFloat? = nil, action: @escaping () -> Void) {
        self.text = text
        self.icon = icon
        self.width = width
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Label {
                Text(text)
                    .textStyle(MailTextStyle.caption)
            } icon: {
                Image(resource: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
            }
            .dynamicLabelStyle(sizeClass: sizeClass ?? .regular)
        }
        .frame(width: width, alignment: .center)
    }
}

struct ToolbarButton_Previews: PreviewProvider {
    static var previews: some View {
        ToolbarButton(text: "Preview", icon: MailResourcesAsset.folder) { /* Preview */ }
    }
}
