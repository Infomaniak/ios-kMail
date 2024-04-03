/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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

import InfomaniakCore
import InfomaniakDI
import MailResources
import SwiftUI

extension View {
    func composeMessageToolbar(dismissHandler: @escaping () -> Void) -> some View {
        modifier(ComposeMessageToolbarModifier(dismissHandler: dismissHandler))
    }
}

struct ComposeMessageToolbarModifier: ViewModifier {
    @LazyInjectService private var platformDetector: PlatformDetectable

    let dismissHandler: () -> Void

    func body(content: Content) -> some View {
        content
            .navigationTitle(MailResourcesStrings.Localizable.buttonNewMessage)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !platformDetector.isMac {
                        CloseButton(dismissHandler: dismissHandler)
                    }
                }
            }
    }
}
