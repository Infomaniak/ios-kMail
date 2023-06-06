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

import MailResources
import SwiftUI

struct BottomBar<Items: View>: ViewModifier {
    let isVisible: Bool

    @ViewBuilder var items: () -> Items

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom) {
                if isVisible {
                    BottomBarView(items: items)
                }
            }
    }
}

extension View {
    func bottomBar<Items: View>(isVisible: Bool = true, @ViewBuilder items: @escaping () -> Items) -> some View {
        modifier(BottomBar(isVisible: isVisible, items: items))
    }
}

struct BottomBarView<Items: View>: View {
    @ViewBuilder var items: () -> Items

    var body: some View {
        VStack {
            Divider()
                .frame(height: 1)
                .overlay(Color(uiColor: .systemGray3))

            HStack {
                Spacer(minLength: 8)
                items()
                Spacer(minLength: 8)
            }
            .padding(.vertical, 4)
        }
        .background(MailResourcesAsset.backgroundTabBarColor.swiftUIColor)
    }
}

struct BottomBarView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            VStack {
                Text("View #1")
            }
            .navigationTitle("Title")
            .bottomBar {
                Text("Coucou")
            }
        }
    }
}
