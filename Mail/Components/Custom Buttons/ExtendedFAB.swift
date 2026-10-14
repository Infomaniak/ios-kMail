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

import DesignSystem
import IKSnackbar
import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import SwiftUI

struct ExtendedFAB: View {
    @Environment(\.ikFloatingActionButtonPlacement) private var placement

    /// Trigger a sensory feedback each time the value changes
    @State private var didTapButton = false
    @State private var snackBarInset: CGFloat = 0

    let title: String
    let icon: MailResourcesImages
    let isExtended: Bool
    let inactiveReason: String?
    let action: () -> Void

    var body: some View {
        Button {
            didTapButton.toggle()

            if let inactiveReason {
                @InjectService var snackbarPresenter: IKSnackBarPresentable
                snackbarPresenter.show(message: inactiveReason)
            } else {
                action()
            }
        } label: {
            switch placement {
            case .floating:
                HStack(spacing: 0) {
                    icon
                        .iconSize(.medium)

                    Text(title)
                        .lineLimit(1)
                        .padding(.leading, value: .mini)
                        .frame(width: isExtended ? nil : 0)
                        .clipped()
                }
            case .toolbar:
                Label(title, asset: icon.swiftUIImage)
                    .labelStyle(.iconOnly)
            }
        }
        .accessibilityLabel(title)
        .ikSensoryFeedback(.impact(weight: .heavy), trigger: didTapButton)
        .snackBarAware(
            inset: placement == .floating ? snackBarInset : 0,
            removeOnDisappear: UserDefaults.shared.autoAdvance != .listOfThread
        )
        .overlay {
            ViewGeometry(key: ViewHeightKey.self, property: \.size.height)
        }
        .onPreferenceChange(ViewHeightKey.self) { value in
            // Core UI adds a bottom padding below the floating button
            snackBarInset = value + IKPadding.medium
        }
    }
}

#Preview {
    List {}
        .ikFloatingActionButton(style: .ikFloatingActionButton(isExtended: true)) {
            ExtendedFAB(
                title: MailResourcesStrings.Localizable.buttonNewMessage,
                icon: MailResourcesAsset.pencil,
                isExtended: true,
                inactiveReason: nil
            ) {
                /* Preview */
            }
        }
}
