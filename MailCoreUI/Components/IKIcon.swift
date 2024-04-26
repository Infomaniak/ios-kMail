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

public struct IKIcon: View {
    public enum Size: CGFloat {
        /// 12pt icon
        case small = 12
        /// 16pt icon
        case regular = 16
        /// 24pt icon
        case large = 24
    }

    let icon: Image
    let size: Size

    public init(_ icon: Image, size: Size = .regular) {
        self.icon = icon
        self.size = size
    }

    public init(_ icon: MailResourcesImages, size: Size = .regular) {
        self.init(icon.swiftUIImage, size: size)
    }

    public var body: some View {
        icon
            .resizable()
            .scaledToFit()
            .frame(width: size.rawValue, height: size.rawValue)
    }
}

#Preview {
    HStack(spacing: UIPadding.regular) {
        IKIcon(MailResourcesAsset.pencilPlain, size: .small)
        IKIcon(MailResourcesAsset.pencilPlain, size: .regular)
        IKIcon(MailResourcesAsset.pencilPlain, size: .large)
    }
}
