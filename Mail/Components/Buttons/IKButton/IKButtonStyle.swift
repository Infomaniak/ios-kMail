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
import SwiftUI

struct IKButtonStyle: ButtonStyle {
    @Environment(\.mailButtonLoading) private var isLoading: Bool

    let isPlain: Bool

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            configuration.label
                .opacity(isLoading ? 0 : 1)

            LoadingButtonProgressView(plain: isPlain)
                .opacity(isLoading ? 1 : 0)
        }
        .scaleEffect(CGSize(width: configuration.isPressed ? 0.9 : 1.0, height: configuration.isPressed ? 0.9 : 1.0))
        .animation(.spring, value: configuration.isPressed)
        .allowsHitTesting(!isLoading)
    }
}

#Preview {
    VStack(spacing: UIPadding.medium) {
        Button("Hello, World!", systemImage: "globe") {
            /* Preview */
        }
        .buttonStyle(IKButtonStyle(isPlain: false))

        Button("Hello, World!", systemImage: "globe") {
            /* Preview */
        }
        .buttonStyle(IKButtonStyle(isPlain: false))
        .mailButtonLoading(true)
    }
}
