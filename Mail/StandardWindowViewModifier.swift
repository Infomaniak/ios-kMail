/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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

import InfomaniakCore
import MailCore
import SwiftUI

extension View {
    func standardWindow() -> some View {
        modifier(StandardWindowViewModifier())
    }
}

struct StandardWindowViewModifier: ViewModifier {
    @AppStorage(UserDefaults.shared.key(.accentColor), store: .shared) private var accentColor = DefaultPreferences.accentColor
    @AppStorage(UserDefaults.shared.key(.theme), store: .shared) private var theme = DefaultPreferences.theme

    func body(content: Content) -> some View {
        content
            .detectCompactWindow()
            .onAppear {
                updateUI(accent: accentColor, theme: theme)
            }
            .onChange(of: theme) { newTheme in
                updateUI(accent: accentColor, theme: newTheme)
            }
            .onChange(of: accentColor) { newAccentColor in
                updateUI(accent: newAccentColor, theme: theme)
            }
        #if targetEnvironment(macCatalyst)
            .introspect(.window, on: .iOS(.v16, .v17)) { window in
                if let titlebar = window.windowScene?.titlebar {
                    titlebar.titleVisibility = .hidden
                    titlebar.toolbar = nil
                }
            }
        #endif
    }

    func updateUI(accent: AccentColor, theme: Theme) {
        let allWindows = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap(\.windows)
        for window in allWindows {
            window.updateUI(accent: accent, theme: theme)
        }
    }
}
