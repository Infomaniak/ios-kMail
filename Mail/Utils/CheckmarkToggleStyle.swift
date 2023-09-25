//
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

struct CheckmarkToggleStyle: ToggleStyle {
    let tintColor: Color
    let textColor: Color

    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: UIPadding.small) {
                ZStack {
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(MailResourcesAsset.textTertiaryColor.swiftUIColor, lineWidth: 1)

                    Group {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(tintColor)

                        MailResourcesAsset.check.swiftUIImage
                            .resizable()
                            .foregroundColor(MailResourcesAsset.backgroundColor.swiftUIColor)
                            .padding(2)
                    }
                    .opacity(configuration.isOn ? 1 : 0)
                }
                .frame(width: 16, height: 16)

                configuration.label
                    .foregroundColor(textColor)
            }
        }
    }
}
