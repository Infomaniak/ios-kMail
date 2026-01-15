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

import DesignSystem
import InfomaniakCoreSwiftUI
import MailCore
import MailCoreUI
import SwiftUI

struct SettingsSubMenuLabel: View {
    let title: String
    var subtitle: String?
    var icon: Image?

    var body: some View {
        HStack(spacing: IKPadding.medium) {
            icon

            VStack(alignment: .leading) {
                Text(title)
                    .textStyle(.body)
                if let subtitle {
                    Text(subtitle)
                        .textStyle(.bodySmallTertiary)
                }
            }
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)

            ChevronIcon(direction: .right)
        }
        .settingsItem()
    }
}

struct DeepLinkSettingsSubMenuCell: View {
    let title: String
    var subtitle: String?
    var icon: Image?
    let value: SettingsDestination

    var body: some View {
        NavigationLink(value: value) {
            SettingsSubMenuLabel(title: title, subtitle: subtitle, icon: icon)
        }
    }
}

struct SettingsSubMenuCell<Content: View>: View {
    let title: String
    var subtitle: String?
    var icon: Image?
    @ViewBuilder var destination: () -> Content

    var body: some View {
        NavigationLink(destination: destination) {
            SettingsSubMenuLabel(title: title, subtitle: subtitle, icon: icon)
        }
    }
}

#Preview {
    SettingsSubMenuCell(title: "Settings sub-menu") { EmptyView() }
}
