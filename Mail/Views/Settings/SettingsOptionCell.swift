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

struct SettingsOptionCell: View {
    let icon: Image?
    let title: String
    let subtitle: String
    let option: SettingsOption

    private var workInProgress: Bool {
        return option == .externalContentOption || option == .forwardMessageOption
    }

    init(icon: Image? = nil, title: String, subtitle: String, option: SettingsOption) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.option = option
    }

    var body: some View {
        if !workInProgress {
            NavigationLink(destination: option.getDestination()) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    icon
                    VStack(alignment: .leading) {
                        Text(title)
                            .textStyle(.body)
                        Text(subtitle)
                            .textStyle(.calloutQuaternary)
                    }
                }
            }
        }
    }
}

struct SettingsOptionCell_Previews: PreviewProvider {
    static var previews: some View {
        SettingsOptionCell(title: "Theme", subtitle: "Theme", option: .themeOption)
    }
}
