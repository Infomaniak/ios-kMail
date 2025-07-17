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

extension ReactionsDetailsView.SelectionType {
    var buttonLabel: String {
        switch self {
        case .all:
            return MailResourcesStrings.Localizable.buttonAllReactions
        case .reaction(let uIMessageReaction):
            return uIMessageReaction.formatted()
        }
    }
}

struct ReactionsDetailsButton: View {
    @Binding var currentSelection: ReactionsDetailsView.SelectionType?

    let selectionType: ReactionsDetailsView.SelectionType
    let namespace: Namespace.ID

    private var isSelected: Bool {
        currentSelection == selectionType
    }

    private let animation = Animation.default

    var body: some View {
        Button {
            withAnimation(animation) {
                currentSelection = selectionType
            }
        } label: {
            Text(selectionType.buttonLabel)
                .textStyle(.bodyMedium)
                .padding(.horizontal, value: .small)
                .padding(.vertical, value: .mini)
        }
        .overlay(alignment: .bottom) {
            if currentSelection == selectionType {
                Capsule()
                    .fill(Color.accentColor)
                    .frame(height: 2)
                    .matchedGeometryEffect(id: "SelectedCapsule", in: namespace)
            }
        }
        .animation(animation, value: currentSelection)
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @Namespace var animation
    ReactionsDetailsButton(currentSelection: .constant(.all), selectionType: .all, namespace: animation)
}
