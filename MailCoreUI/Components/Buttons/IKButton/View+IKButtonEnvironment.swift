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

// MARK: - EnvironmentKey

struct IKButtonPrimaryStyleKey: EnvironmentKey {
    static var defaultValue: any ShapeStyle = TintShapeStyle.tint
}

struct IKButtonSecondaryStyleKey: EnvironmentKey {
    static var defaultValue: any ShapeStyle = UserDefaults.shared.accentColor.onAccent.swiftUIColor
}

struct IKButtonFullWidthKey: EnvironmentKey {
    static var defaultValue = false
}

struct IKButtonLoadingKey: EnvironmentKey {
    static var defaultValue = false
}

// MARK: - EnvironmentValues

public extension EnvironmentValues {
    var ikButtonPrimaryStyle: any ShapeStyle {
        get { self[IKButtonPrimaryStyleKey.self] }
        set { self[IKButtonPrimaryStyleKey.self] = newValue }
    }

    var ikButtonSecondaryStyle: any ShapeStyle {
        get { self[IKButtonSecondaryStyleKey.self] }
        set { self[IKButtonSecondaryStyleKey.self] = newValue }
    }

    var ikButtonFullWidth: Bool {
        get { self[IKButtonFullWidthKey.self] }
        set { self[IKButtonFullWidthKey.self] = newValue }
    }

    var ikButtonLoading: Bool {
        get { self[IKButtonLoadingKey.self] }
        set { self[IKButtonLoadingKey.self] = newValue }
    }
}

// MARK: - View functions

public extension View {
    func ikButtonPrimaryStyle(_ style: any ShapeStyle) -> some View {
        environment(\.ikButtonPrimaryStyle, style)
    }

    func ikButtonSecondaryStyle(_ style: any ShapeStyle) -> some View {
        environment(\.ikButtonSecondaryStyle, style)
    }

    func ikButtonFullWidth(_ fullWidth: Bool) -> some View {
        environment(\.ikButtonFullWidth, fullWidth)
    }

    func ikButtonLoading(_ loading: Bool) -> some View {
        environment(\.ikButtonLoading, loading)
    }
}
