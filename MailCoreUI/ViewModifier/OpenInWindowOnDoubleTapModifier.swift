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
import InfomaniakDI
import MailCore
import SwiftUI

public extension View {
    func openInWindowOnDoubleTap<Value: Codable & Hashable>(windowId: String, value: Value) -> some View {
        if #available(iOS 16.0, *) {
            return self.modifier(OpenInWindowOnDoubleTapModifier(windowId: windowId, value: value))
        } else {
            return self
        }
    }
}

@available(iOS 16.0, *)
public struct OpenInWindowOnDoubleTapModifier<Value: Codable & Hashable>: ViewModifier {
    @InjectService private var platformDetector: PlatformDetectable

    @Environment(\.openWindow) private var openWindow

    let windowId: String
    let value: Value

    public func body(content: Content) -> some View {
        content.simultaneousGesture(
            TapGesture(count: 2).onEnded {
                if platformDetector.isMac {
                    openWindow(
                        id: windowId,
                        value: value
                    )
                }
            }
        )
    }
}
