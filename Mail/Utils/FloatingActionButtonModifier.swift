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

import MailCore
import MailResources
import SwiftUI

struct FloatingActionButtonModifier: ViewModifier {
    let isEnabled: Bool
    let icon: MailResourcesImages
    let title: String
    let action: () -> Void

    @State private var snackBarAwareModifier = SnackBarAwareModifier(inset: 0)

    func body(content: Content) -> some View {
        ZStack(alignment: .bottomTrailing) {
            content

            if isEnabled {
                MailButton(icon: icon, label: title, action: action)
                    .mailButtonStyle(.floatingActionButton)
                    .padding(.trailing, value: .medium)
                    .padding(.bottom, UIPadding.floatingButtonBottom)
                    .modifier(snackBarAwareModifier)
                    .accessibilityLabel(title)
                    .overlay {
                        ViewGeometry(key: ViewHeightKey.self, property: \.size.height)
                    }
                    .onPreferenceChange(ViewHeightKey.self) { value in
                        snackBarAwareModifier.inset = value
                    }
            }
        }
        .ignoresSafeArea(.keyboard)
    }
}

extension View {
    func floatingActionButton(isEnabled: Bool = true, icon: MailResourcesImages, title: String,
                              action: @escaping () -> Void) -> some View {
        modifier(FloatingActionButtonModifier(isEnabled: isEnabled, icon: icon, title: title, action: action))
    }
}
