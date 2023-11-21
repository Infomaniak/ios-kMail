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

struct IKButtonLoadingModifier: ViewModifier {
    @Environment(\.mailButtonLoading) private var isLoading: Bool

    let isPlain: Bool

    func body(content: Content) -> some View {
        ZStack {
            content
                .opacity(isLoading ? 0 : 1)

            LoadingButtonProgressView(plain: isPlain)
                .opacity(isLoading ? 1 : 0)
        }
    }
}

struct IKExpandableButtonModifier: ViewModifier {
    @Environment(\.mailButtonFullWidth) private var fullWidth: Bool

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: fullWidth ? UIConstants.componentsMaxWidth : nil)
    }
}

struct IKLayoutButton: ViewModifier {
    @Environment(\.controlSize) private var controlSize

    private var buttonHeight: CGFloat {
        if controlSize == .large {
            return UIConstants.buttonMediumHeight
        } else {
            return UIConstants.buttonSmallHeight
        }
    }

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, value: .medium)
            .frame(height: buttonHeight)
    }
}

struct IKTapAnimationModifier: ViewModifier {
    let isPressed: Bool

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .animation(.spring, value: isPressed)
    }
}
