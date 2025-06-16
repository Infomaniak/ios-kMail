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

import MailCore
import MailResources
import SwiftUI
import SwiftUIIntrospect

public struct SegmentedControlModifier: ViewModifier {
    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor

    public func body(content: Content) -> some View {
        content
            .introspect(.picker(style: .segmented), on: .iOS(.v15, .v16, .v17, .v18, .v26)) { segmentedControl in
                segmentedControl.selectedSegmentTintColor = accentColor.primary.color
                segmentedControl.setTitleTextAttributes([.foregroundColor: accentColor.onAccent.color], for: .selected)
                segmentedControl.setTitleTextAttributes([.foregroundColor: accentColor.primary.color], for: .normal)
                segmentedControl.backgroundColor = accentColor.secondary.color
            }
    }
}

public extension View {
    func ikSegmentedControl() -> some View {
        modifier(SegmentedControlModifier())
    }
}
