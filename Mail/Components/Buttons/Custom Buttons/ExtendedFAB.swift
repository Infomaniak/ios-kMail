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

import MailResources
import SwiftUI

struct ExtendedFAB: View {
    /// Trigger a sensory feedback each time the value changes
    @State private var didTapButton = false

    let title: String
    let icon: MailResourcesImages
    let isExtended: Bool
    let action: () -> Void

    var body: some View {
        Button {
            didTapButton.toggle()
            action()
        } label: {
            HStack(spacing: 0) {
                IKIcon(size: .medium, image: icon)

                Text(title)
                    .lineLimit(1)
                    .padding(.leading, value: .small)
                    .frame(width: isExtended ? nil : 0)
                    .clipped()
            }
        }
        .buttonStyle(.ikFloatingAppButton(isExtended: isExtended))
        .ikSensoryFeedback(.impact(weight: .heavy), trigger: didTapButton)
    }
}

#Preview {
    ExtendedFAB(title: MailResourcesStrings.Localizable.buttonNewMessage, icon: MailResourcesAsset.pencil, isExtended: true) {
        /* Preview */
    }
}
