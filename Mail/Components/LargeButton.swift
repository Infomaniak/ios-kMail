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

import SwiftUI

struct LargeButton<Label>: View where Label: View {
    let isLoading: Bool
    let action: () -> Void
    let label: Label

    init(isLoading: Bool = false, action: @escaping () -> Void, @ViewBuilder label: () -> Label) {
        self.isLoading = isLoading
        self.action = action
        self.label = label()
    }

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                } else {
                    label
                        .textStyle(.header5OnAccent)
                }
            }
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.roundedRectangle(radius: 16))
        .padding(.horizontal, 24)
        .disabled(isLoading)
    }
}

extension LargeButton where Label == Text {
    init(title: String, isLoading: Bool = false, action: @escaping () -> Void) {
        self.init(isLoading: isLoading, action: action) {
            Text(title)
        }
    }
}

struct LargeButton_Previews: PreviewProvider {
    static var previews: some View {
        LargeButton(title: "Button") { /* Preview */ }
    }
}
