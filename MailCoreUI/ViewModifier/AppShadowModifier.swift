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

import MailResources
import SwiftUI

public struct AppShadowModifier: ViewModifier {
    public func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
        } else {
            ZStack {
                MailResourcesAsset.backgroundColor.swiftUIColor
                    .ignoresSafeArea()
                    .shadow(color: .black.opacity(0.08), radius: 2.5, x: 0.5, y: 0.5)
                content
            }
        }
    }
}

public extension View {
    func appShadow() -> some View {
        modifier(AppShadowModifier())
    }
}
