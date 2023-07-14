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
import UIKit

struct NavigationBarStyleViewModifier: ViewModifier {
    @State private var navigationViewController: UINavigationController?
    let standardAppearance: UINavigationBarAppearance
    let scrollEdgeAppearance: UINavigationBarAppearance?
    let compactAppearance: UINavigationBarAppearance?

    @State private var previousStandardAppearance: UINavigationBarAppearance?
    @State private var previousScrollEdgeAppearance: UINavigationBarAppearance?
    @State private var previousCompactAppearance: UINavigationBarAppearance?

    func body(content: Content) -> some View {
        content
            .introspectNavigationController { navigationViewController in
                guard self.navigationViewController != navigationViewController else {
                    return
                }
                self.navigationViewController = navigationViewController
                updateAppearanceNavigationController()
            }
            .onAppear {
                previousCompactAppearance = navigationViewController?.navigationBar.standardAppearance
                previousScrollEdgeAppearance = navigationViewController?.navigationBar.scrollEdgeAppearance
                previousCompactAppearance = navigationViewController?.navigationBar.compactAppearance

                updateAppearanceNavigationController()
            }
            .onDisappear {
                if let previousStandardAppearance {
                    navigationViewController?.navigationBar.standardAppearance = previousStandardAppearance
                }
                navigationViewController?.navigationBar.scrollEdgeAppearance = previousScrollEdgeAppearance
                navigationViewController?.navigationBar.compactAppearance = previousCompactAppearance
            }
    }

    private func updateAppearanceNavigationController() {
        navigationViewController?.navigationBar.standardAppearance = standardAppearance
        navigationViewController?.navigationBar.scrollEdgeAppearance = scrollEdgeAppearance
        navigationViewController?.navigationBar.compactAppearance = compactAppearance
    }
}
