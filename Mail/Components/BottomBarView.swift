//
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
    @Binding var isHidden: Bool

    @ViewBuilder var items: () -> Items

    func body(content: Content) -> some View {
        VStack {
            content
            Spacer(minLength: 0)
            BottomBarView(isHidden: $isHidden, items: items)
        }
    }
}

extension View {
    func bottomBar<Items: View>(isHidden: Binding<Bool> = .constant(false), @ViewBuilder items: @escaping () -> Items) -> some View {
        modifier(BottomBar(isHidden: isHidden, items: items))
    }
}

struct BottomBarView<Items: View>: View {
    @Binding var isHidden: Bool

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
            .padding(.top, 4)
        }
        .background(MailResourcesAsset.backgroundTabBarColor.swiftUIColor)
        .opacity(isHidden ? 1 : 0)
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
