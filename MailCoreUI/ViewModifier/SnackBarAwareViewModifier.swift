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

import InfomaniakCoreCommonUI
import InfomaniakDI
import MailCore
import SwiftUI

public extension View {
    func snackBarAware(inset: CGFloat, removeOnDisappear: Bool = true) -> some View {
        modifier(SnackBarAwareViewModifier(inset: inset, removeOnDisappear: removeOnDisappear))
    }
}

public struct SnackBarAwareViewModifier: ViewModifier {
    @LazyInjectService var avoider: IKSnackBarAvoider

    let removeOnDisappear: Bool

    public var inset: CGFloat {
        didSet {
            avoider.addAvoider(inset: inset)
        }
    }

    public init(inset: CGFloat, removeOnDisappear: Bool) {
        self.inset = inset
        self.removeOnDisappear = removeOnDisappear
    }

    public func body(content: Content) -> some View {
        content
            .onChange(of: inset) { newValue in
                avoider.addAvoider(inset: newValue)
            }
            .onAppear {
                avoider.addAvoider(inset: inset)
            }
            .onDisappear {
                if avoider.snackBarInset == inset && removeOnDisappear {
                    avoider.removeAvoider()
                }
            }
    }
}
