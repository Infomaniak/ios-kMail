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

import InfomaniakCoreCommonUI
import InfomaniakDI
import SwiftUI

public struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIInterfaceOrientation?) -> Void

    private var orientationManager: OrientationManageable

    @State private var lastOrientation: UIInterfaceOrientation?

    public init(action: @escaping (UIInterfaceOrientation?) -> Void) {
        let orientationSource = InjectService<OrientationManageable>().wrappedValue
        let orientation = orientationSource.interfaceOrientation
        self.action = action
        orientationManager = orientationSource
        lastOrientation = orientation
    }

    public func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                guard let currentOrientation = orientationManager.interfaceOrientation else {
                    return
                }
                if lastOrientation != currentOrientation {
                    lastOrientation = currentOrientation
                    action(currentOrientation)
                }
            }
    }
}

/// A View wrapper to make the modifier easier to use
public extension View {
    func onRotate(perform action: @escaping (UIInterfaceOrientation?) -> Void) -> some View {
        modifier(DeviceRotationViewModifier(action: action))
    }
}
