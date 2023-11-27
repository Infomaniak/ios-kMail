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

// MARK: - Loading Effect

struct IKButtonLoadingModifier: ViewModifier {
    @Environment(\.ikButtonLoading) private var isLoading: Bool

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

// MARK: - Control Size

struct IKButtonControlSizeModifier: ViewModifier {
    @Environment(\.controlSize) private var controlSize

    private var font: Font {
        if controlSize == .small {
            return MailTextStyle.bodySmall.font
        } else {
            return MailTextStyle.bodyMedium.font
        }
    }

    func body(content: Content) -> some View {
        content
            .font(font)
    }
}

// MARK: - Expandable Button

struct IKButtonExpandableModifier: ViewModifier {
    @Environment(\.ikButtonFullWidth) private var isFullWidth: Bool

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: isFullWidth ? UIConstants.componentsMaxWidth : nil)
    }
}

// MARK: - Layout

struct IKButtonLayout: ViewModifier {
    @Environment(\.controlSize) private var controlSize

    var isInlined = false

    private var buttonHeight: CGFloat? {
        if isInlined {
            return nil
        } else if controlSize == .large {
            return UIConstants.buttonMediumHeight
        } else {
            return UIConstants.buttonSmallHeight
        }
    }

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, isInlined ? 0 : UIPadding.medium)
            .frame(height: buttonHeight)
    }
}

// MARK: - Tap Animation

enum IKButtonTapAnimation {
    case scale, opacity
}

struct IKButtonScaleAnimationModifier: ViewModifier {
    let isPressed: Bool

    func body(content: Content) -> some View {
        content
            .brightness(isPressed ? 0.1 : 0)
            .scaleEffect(isPressed ? 0.95 : 1.0)
    }
}

struct IKButtonOpacityAnimationModifier: ViewModifier {
    let isPressed: Bool

    func body(content: Content) -> some View {
        content
            .opacity(isPressed ? 0.4 : 1.0)
    }
}

// MARK: - Filled Button

struct IKButtonFilledModifier: ViewModifier {
    @Environment(\.ikButtonPrimaryStyle) private var ikButtonPrimaryStyle: any ShapeStyle
    @Environment(\.ikButtonSecondaryStyle) private var ikButtonSecondaryStyle: any ShapeStyle
    @Environment(\.ikButtonLoading) private var isLoading: Bool

    @Environment(\.isEnabled) private var isEnabled

    private var foreground: any ShapeStyle {
        guard isEnabled && !isLoading else { return MailTextStyle.bodyMediumOnDisabled.color }
        return ikButtonSecondaryStyle
    }

    private var background: any ShapeStyle {
        guard isEnabled && !isLoading else { return MailResourcesAsset.textTertiaryColor.swiftUIColor }
        return ikButtonPrimaryStyle
    }

    func body(content: Content) -> some View {
        content
            .foregroundStyle(AnyShapeStyle(foreground))
            .background(AnyShapeStyle(background), in: RoundedRectangle(cornerRadius: UIConstants.buttonsRadius))
    }
}
