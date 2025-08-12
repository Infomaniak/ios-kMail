/*
 Infomaniak Mail - iOS App
 Copyright (C) 2025 Infomaniak Network SA

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

struct ReactionsDetailsButton: View {
    @Binding var currentSelection: ReactionSelectionType?

    let label: String
    let selectionType: ReactionSelectionType
    let namespace: Namespace.ID

    private static let geometryEffect = "SelectedCapsule"

    private var isSelected: Bool {
        currentSelection == selectionType
    }

    private let animation = Animation.default.speed(2)

    var body: some View {
        Button {
            withAnimation(animation) {
                currentSelection = selectionType
            }
        } label: {
            Text(label)
                .textStyle(.bodyMedium)
                .padding(.horizontal, value: .small)
                .padding(.vertical, value: .mini)
                .frame(minWidth: 56)
        }
        .overlay(alignment: .bottom) {
            if currentSelection == selectionType {
                Capsule()
                    .fill(Color.accentColor)
                    .frame(height: 2)
                    .matchedGeometryEffect(id: Self.geometryEffect, in: namespace)
            }
        }
        .animation(animation, value: currentSelection)
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @Namespace var animation
    ReactionsDetailsButton(currentSelection: .constant(.all), label: "all", selectionType: .all, namespace: animation)
}
