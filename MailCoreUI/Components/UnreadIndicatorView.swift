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

import SwiftUI

public struct UnreadIndicatorView: View {
    public static let size: CGFloat = 8

    let hidden: Bool

    public init(hidden: Bool = false) {
        self.hidden = hidden
    }

    public var body: some View {
        Circle()
            .frame(width: Self.size, height: Self.size)
            .foregroundStyle(hidden ? .clear : .accentColor)
    }
}

#Preview {
    UnreadIndicatorView(hidden: false)
}
