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

import MailCore
import MailResources
import SwiftUI

public struct ToolbarButtonLabel: View {
    @Environment(\.verticalSizeClass) private var sizeClass

    let text: String
    let icon: Image

    public init(text: String, icon: Image) {
        self.text = text
        self.icon = icon
    }

    public var body: some View {
        Label {
            Text(text)
                .textStyle(MailTextStyle.labelMediumAccent)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
        } icon: {
            icon
                .resizable()
                .frame(width: 24, height: 24)
        }
        .dynamicLabelStyle(sizeClass: sizeClass ?? .regular)
    }
}

public struct ToolbarButton: View {
    let text: String
    let icon: Image
    let action: () -> Void

    public init(text: String, icon: Image, action: @escaping () -> Void) {
        self.text = text
        self.icon = icon
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            ToolbarButtonLabel(text: text, icon: icon)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ToolbarButton(text: "Preview", icon: MailResourcesAsset.folder.swiftUIImage) { /* Preview */ }
}
