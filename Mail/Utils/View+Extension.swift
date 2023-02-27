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

import InfomaniakCoreUI
import MailCore
import MailResources
import SwiftUI

struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIInterfaceOrientation?) -> Void
    @State private var lastOrientation = UIApplication.shared.mainSceneKeyWindow?.windowScene?.interfaceOrientation

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                if lastOrientation != UIApplication.shared.mainSceneKeyWindow?.windowScene?.interfaceOrientation {
                    lastOrientation = UIApplication.shared.mainSceneKeyWindow?.windowScene?.interfaceOrientation
                    action(lastOrientation)
                }
            }
    }
}

// A View wrapper to make the modifier easier to use
extension View {
    func onRotate(perform action: @escaping (UIInterfaceOrientation?) -> Void) -> some View {
        modifier(DeviceRotationViewModifier(action: action))
    }

    @ViewBuilder
    func modifyIf<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    func foregroundColor(_ color: InfomaniakCoreColor) -> some View {
        return foregroundColor(Color(color.color))
    }

    func foregroundColor(_ color: MailResourcesColors) -> some View {
        return foregroundColor(color.swiftUiColor)
    }

    func tint(_ tint: MailResourcesColors) -> some View {
        return self.tint(tint.swiftUiColor)
    }

    func navigationBarThreadListStyle() -> some View {
        if #available(iOS 16.0, *) {
            return toolbarBackground(MailResourcesAsset.backgroundNavBarColor.swiftUiColor, for: .navigationBar)
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
            return toolbarBackground(MailResourcesAsset.backgroundColor.swiftUiColor, for: .navigationBar)
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
}
