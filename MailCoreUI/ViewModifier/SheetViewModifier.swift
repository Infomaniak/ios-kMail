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

public typealias DismissModalAction = () -> Void

public struct DismissModalKey: EnvironmentKey {
    public static let defaultValue: DismissModalAction = { /* dismiss nothing by default */ }
}

public extension EnvironmentValues {
    var dismissModal: DismissModalAction {
        get {
            return self[DismissModalKey.self]
        }
        set {
            self[DismissModalKey.self] = newValue
        }
    }
}

public extension View {
    func sheetViewStyle() -> some View {
        modifier(SheetViewModifier())
    }
}

public struct SheetViewModifier: ViewModifier {
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public func body(content: Content) -> some View {
        NavigationView {
            content
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        CloseButton(dismissAction: dismiss)
                    }
                }
        }
        .navigationViewStyle(.stack)
        .environment(\.dismissModal) {
            dismiss()
        }
    }
}
