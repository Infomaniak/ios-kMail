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

import DesignSystem
import InfomaniakCoreCommonUI
import MailCore
import MailResources
import MyKSuite
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
        if #available(iOS 26.0, *) {
            return self
        } else {
            return modifier(NavigationBarStyleViewModifier(
                standardAppearance: appearance,
                scrollEdgeAppearance: appearance,
                compactAppearance: appearance
            ))
        }
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

    func emptyState<T>(isEmpty: Bool, @ViewBuilder emptyView: () -> T) -> some View where T: View {
        overlay {
            if isEmpty {
                emptyView()
            }
        }
    }
}

public extension View {
    func mailCustomAlert<Item, Content>(
        item: Binding<Item?>,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View
        where Item: Identifiable, Content: View {
        customAlert(
            item: item,
            backgroundColor: MailResourcesAsset.backgroundTertiaryColor.swiftUIColor,
            content: content
        )
    }

    func mailCustomAlert<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        customAlert(
            isPresented: isPresented,
            backgroundColor: MailResourcesAsset.backgroundTertiaryColor.swiftUIColor,
            content: content
        )
    }
}

public extension View {
    func mailDiscoveryPresenter<ModalContent: View>(
        isPresented: Binding<Bool>,
        bottomPadding: CGFloat = IKPadding.medium,
        @ViewBuilder modalContent: @escaping () -> ModalContent
    ) -> some View {
        discoveryPresenter(
            isPresented: isPresented,
            bottomPadding: bottomPadding,
            alertBackgroundColor: MailResourcesAsset.backgroundTertiaryColor.swiftUIColor,
            sheetBackgroundColor: MailResourcesAsset.backgroundSecondaryColor.swiftUIColor,
            modalContent: modalContent
        )
    }
}

public extension View {
    func mailFloatingPanel<Content: View>(
        isPresented: Binding<Bool>,
        title: String? = nil,
        closeButtonHidden: Bool = false,
        bottomPadding: CGFloat = IKPadding.medium,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        floatingPanel(
            isPresented: isPresented,
            title: title,
            closeButtonHidden: closeButtonHidden,
            backgroundColor: MailResourcesAsset.backgroundSecondaryColor.swiftUIColor,
            bottomPadding: bottomPadding,
            content: content
        )
    }

    func mailFloatingPanel<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        title: String? = nil,
        bottomPadding: CGFloat = IKPadding.medium,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        floatingPanel(
            item: item,
            backgroundColor: MailResourcesAsset.backgroundSecondaryColor.swiftUIColor,
            title: title,
            bottomPadding: bottomPadding,
            content: content
        )
    }
}

public extension View {
    func mailMyKSuiteFloatingPanel(
        isPresented: Binding<Bool>,
        configuration: MyKSuiteConfiguration
    ) -> some View {
        myKSuitePanel(
            isPresented: isPresented,
            backgroundColor: MailResourcesAsset.backgroundSecondaryColor.swiftUIColor,
            configuration: configuration
        )
    }
}
