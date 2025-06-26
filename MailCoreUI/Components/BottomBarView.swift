/*
 Infomaniak Mail - iOS App
 Copyright (C) 2023 Infomaniak Network SA

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

public struct BottomBar<Items: View>: ViewModifier {
    let isVisible: Bool
    @ViewBuilder var items: () -> Items

    public func body(content: Content) -> some View {
        VStack(spacing: 0) {
            content
                .frame(maxHeight: .infinity, alignment: .top)

            if isVisible {
                BottomBarView(items: items)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

public extension View {
    func bottomBar<Items: View>(isVisible: Bool = true, @ViewBuilder items: @escaping () -> Items) -> some View {
        modifier(BottomBar(isVisible: isVisible, items: items))
    }
}

public struct BottomBarView<Items: View>: View {
    @State private var hasBottomSafeArea: Bool
    @State private var snackBarAwareModifier: SnackBarAwareModifier

    private let items: Items

    public init(
        hasBottomSafeArea: Bool = true,
        snackBarAwareModifier: SnackBarAwareModifier = SnackBarAwareModifier(inset: 0),
        items: () -> Items
    ) {
        self.hasBottomSafeArea = hasBottomSafeArea
        self.snackBarAwareModifier = snackBarAwareModifier
        self.items = items()
    }

    public var body: some View {
        HStack {
            items
                .padding(.horizontal, value: .mini)
                .frame(maxWidth: .infinity)
        }
        .modifier(snackBarAwareModifier)
        .padding(.top, value: .mini)
        .padding(.bottom, value: hasBottomSafeArea ? .micro : .mini)
        .background(MailResourcesAsset.backgroundTabBarColor.swiftUIColor)
        .overlay(alignment: .top) {
            Divider()
                .frame(height: 1)
                .overlay(Color(uiColor: .systemGray3))
        }
        .overlay {
            ViewGeometry(key: BottomSafeAreaKey.self, property: \.safeAreaInsets.bottom)
        }
        .onPreferenceChange(BottomSafeAreaKey.self) { value in
            hasBottomSafeArea = value > 0
            snackBarAwareModifier.inset = value + 16
        }
    }
}

#Preview {
    NavigationView {
        List {
            Text("View #1")
        }
        .navigationTitle("Title")
        .bottomBar {
            Text("C1")
            Text("C2")
            Text("C3")
            Text("C4")
        }
    }
}
