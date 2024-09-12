/*
 Infomaniak Mail - iOS App
 Copyright (C) 2023 Infomaniak Network SA

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

import InfomaniakCoreUI
import MailCore
import MailResources
import SwiftUI

public extension ToggleStyle where Self == IKCheckmarkToggleStyle {
    static var ikCheckmark: IKCheckmarkToggleStyle {
        IKCheckmarkToggleStyle()
    }
}

public struct IKCheckmarkToggleStyle: ToggleStyle {
    public func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: IKPadding.small) {
                ZStack {
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(MailResourcesAsset.textTertiaryColor.swiftUIColor, lineWidth: 1)

                    Group {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.tint)

                        MailResourcesAsset.check
                            .iconSize(.medium)
                            .foregroundStyle(MailResourcesAsset.backgroundColor)
                            .padding(2)
                    }
                    .opacity(configuration.isOn ? 1 : 0)
                }
                .frame(width: 16, height: 16)

                configuration.label
            }
        }
    }
}

#Preview("Is On") {
    Toggle("Preview Toggle", isOn: .constant(true))
        .toggleStyle(.ikCheckmark)
}

#Preview("Is Off") {
    Toggle("Preview Toggle", isOn: .constant(false))
        .toggleStyle(.ikCheckmark)
}
