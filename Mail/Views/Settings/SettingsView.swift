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

import Introspect
import MailCore
import MailResources
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var menuSheet: MenuSheet

    let isCompact: Bool

    init(isCompact: Bool) {
        self.isCompact = isCompact
    }

    var body: some View {
        ZStack {
            Text("Settings View")
                .font(.system(size: 50))
            List {
                NavigationLink {
                    AccountView()
                } label: {
                    Text("Account")
                }
            }
        }

        .introspectNavigationController { navigationController in
            let navigationBarAppearance = UINavigationBarAppearance()
            navigationBarAppearance.configureWithTransparentBackground()
            navigationBarAppearance.backgroundColor = MailResourcesAsset.backgroundHeaderColor.color
            navigationBarAppearance.largeTitleTextAttributes = [
                .foregroundColor: MailResourcesAsset.primaryTextColor.color,
                .font: UIFont.systemFont(ofSize: 22, weight: .semibold)
            ]

            navigationController.navigationBar.standardAppearance = navigationBarAppearance
            navigationController.navigationBar.compactAppearance = navigationBarAppearance
            navigationController.navigationBar.scrollEdgeAppearance = navigationBarAppearance
            navigationController.hidesBarsOnSwipe = true
        }
        .modifier(SettingsNavigationBar(isCompact: isCompact, sheet: menuSheet))
    }
}

private struct SettingsNavigationBar: ViewModifier {
    var isCompact: Bool

    @ObservedObject var sheet: MenuSheet

    func body(content: Content) -> some View {
        content
            .navigationTitle(MailResourcesStrings.settings)
            .modifyIf(isCompact) { view in
                view.toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            sheet.state = .menuDrawer
                        } label: {
                            Image(uiImage: MailResourcesAsset.burger.image)
                        }
                        .tint(MailResourcesAsset.secondaryTextColor)
                    }
                }
            }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(isCompact: false)
    }
}
