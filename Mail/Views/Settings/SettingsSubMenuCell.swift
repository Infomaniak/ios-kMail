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

import SwiftUI

struct SettingsSubMenuCell<Content: View>: View {
    let title: String
    let subtitle: String?
    let icon: Image?

    @ViewBuilder var destination: () -> Content

    init(title: String, subtitle: String? = nil, icon: Image? = nil, destination: @escaping () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.destination = destination
    }

    var body: some View {
        NavigationLink(destination: destination) {
            HStack {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    icon
                    VStack(alignment: .leading) {
                        Text(title)
                            .textStyle(.body)
                        if let subtitle {
                            Text(subtitle)
                                .textStyle(.bodySmallTertiary)
                        }
                    }
                }
                Spacer()
                ChevronIcon(style: .right)
            }
            .settingsItem()
        }
    }
}

struct SettingsSubMenuCell_Previews: PreviewProvider {
    static var previews: some View {
        SettingsSubMenuCell(title: "Settings sub-menu") { EmptyView() }
    }
}
