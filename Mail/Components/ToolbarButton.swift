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

// MARK: - Environment

struct SmallToolbarKey: EnvironmentKey {
    static var defaultValue = false
}

extension EnvironmentValues {
    var smallToolbar: Bool {
        get { self[SmallToolbarKey.self] }
        set { self[SmallToolbarKey.self] = newValue }
    }
}

extension View {
    func smallToolbar(_ isSmall: Bool) -> some View {
        environment(\.smallToolbar, isSmall)
    }
}

// MARK: - View

struct ToolbarButtonLabel: View {
    @Environment(\.verticalSizeClass) private var sizeClass
    @Environment(\.smallToolbar) private var smallToolbar

    let text: String
    let icon: Image

    var body: some View {
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
        .dynamicLabelStyle(sizeClass: sizeClass ?? .regular, smallToolbar: smallToolbar)
    }
}

struct ToolbarButton: View {
    let text: String
    let icon: Image
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ToolbarButtonLabel(text: text, icon: icon)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ToolbarButton_Previews: PreviewProvider {
    static var previews: some View {
        ToolbarButton(text: "Preview", icon: MailResourcesAsset.folder.swiftUIImage) { /* Preview */ }
    }
}
