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
import InfomaniakCoreSwiftUI
import MailCoreUI
import MailResources
import SwiftUI

struct FloatingActionButtonModifier: ViewModifier {
    let isEnabled: Bool
    let icon: MailResourcesImages
    let title: String
    var isExtended = true
    let action: () -> Void

    @State private var snackBarInset: CGFloat = 0

    func body(content: Content) -> some View {
        ZStack(alignment: .bottomTrailing) {
            content

            if isEnabled {
                ExtendedFAB(title: title, icon: icon, isExtended: isExtended, action: action)
                    .padding(.trailing, value: .large)
                    .padding(.bottom, IKPadding.floatingButtonBottom)
                    .snackBarAware(inset: snackBarInset, removeOnDisappear: UserDefaults.shared.autoAdvance != .listOfThread)
                    .accessibilityLabel(title)
                    .overlay {
                        ViewGeometry(key: ViewHeightKey.self, property: \.size.height)
                    }
                    .onPreferenceChange(ViewHeightKey.self) { value in
                        snackBarInset = value
                    }
            }
        }
        .ignoresSafeArea(.keyboard)
    }
}

extension View {
    func floatingActionButton(
        isEnabled: Bool = true,
        icon: MailResourcesImages,
        title: String,
        isExtended: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        modifier(FloatingActionButtonModifier(
            isEnabled: isEnabled,
            icon: icon,
            title: title,
            isExtended: isExtended,
            action: action
        ))
    }
}
