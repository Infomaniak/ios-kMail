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

import MailResources
import SwiftUI

public struct IKDivider: View {
    public enum DividerType {
        case menu, item, full

        var insets: EdgeInsets {
            switch self {
            case .menu:
                return EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0)
            case .item:
                return EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
            case .full:
                return EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
            }
        }
    }

    let type: DividerType

    public init(type: DividerType = .item) {
        self.type = type
    }

    public var body: some View {
        Divider()
            .frame(height: 1)
            .overlay(MailResourcesAsset.elementsColor.swiftUIColor)
            .padding(type.insets)
    }
}

#Preview {
    IKDivider()
}
