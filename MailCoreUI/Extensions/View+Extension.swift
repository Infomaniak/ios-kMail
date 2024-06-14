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

import InfomaniakCoreUI
import MailCore
import MailResources
import SwiftUI

public extension View {
    @ViewBuilder
    func modifyIf<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    // With iOS 17+, we will be able to make `InfomaniakCoreColor` conform to `ShapeStyle`
    func foregroundStyle(_ color: InfomaniakCoreColor) -> some View {
        return foregroundStyle(Color(color.color))
    }

    // With iOS 17+, we will be able to make `MailResourcesColors` conform to `ShapeStyle`
    func foregroundStyle(_ color: MailResourcesColors) -> some View {
        return foregroundStyle(color.swiftUIColor)
    }

    func tint(_ tint: MailResourcesColors) -> some View {
        return self.tint(tint.swiftUIColor)
    }

    func navigationBarThreadListStyle() -> some View {
        if #available(iOS 16.0, *) {
            return toolbarBackground(UserDefaults.shared.accentColor.navBarBackground.swiftUIColor, for: .navigationBar)
        } else {
            return modifier(NavigationBarStyleViewModifier(
                standardAppearance: BarAppearanceConstants.threadListNavigationBarAppearance,
                scrollEdgeAppearance: BarAppearanceConstants.threadListNavigationBarAppearance,
                compactAppearance: BarAppearanceConstants.threadListNavigationBarAppearance
            ))
        }
    }

    func navigationBarThreadViewStyle(appearance: UINavigationBarAppearance) -> some View {
        return modifier(NavigationBarStyleViewModifier(
            standardAppearance: appearance,
            scrollEdgeAppearance: appearance,
            compactAppearance: appearance
        ))
    }

    func navigationBarSearchListStyle() -> some View {
        if #available(iOS 16.0, *) {
            return toolbarBackground(MailResourcesAsset.backgroundColor.swiftUIColor, for: .navigationBar)
        } else {
            return modifier(NavigationBarStyleViewModifier(
                standardAppearance: BarAppearanceConstants.threadViewNavigationBarAppearance,
                scrollEdgeAppearance: BarAppearanceConstants.threadViewNavigationBarAppearance,
                compactAppearance: nil
            ))
        }
    }

    func toolbarAppStyle() -> some View {
        return onAppear {
            UIToolbar.appearance().standardAppearance = BarAppearanceConstants.threadViewToolbarAppearance
            UIToolbar.appearance().scrollEdgeAppearance = BarAppearanceConstants.threadViewToolbarAppearance
        }
    }

    func emptyState<T>(isEmpty: Bool, @ViewBuilder emptyView: () -> T) -> some View where T: View {
        overlay {
            if isEmpty {
                emptyView()
            }
        }
    }
}
