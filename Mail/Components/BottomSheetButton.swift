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

struct BottomSheetButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textStyle(.bodyMediumOnAccent)
            .padding(.vertical, 18)
            .padding(.horizontal, 24)
            .background(background(configuration: configuration))
            .clipShape(Capsule())
    }

    private func background(configuration: Configuration) -> Color {
        guard isEnabled else { return MailResourcesAsset.progressCircleColor.swiftUIColor }
        return .accentColor.opacity(configuration.isPressed ? 0.8 : 1)
    }
}

struct BottomSheetButton: View {
    var label: String
    var isDisabled = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .textStyle(.bodyMediumOnAccent)
        }
        .buttonStyle(BottomSheetButtonStyle())
        .disabled(isDisabled)
        .animation(.easeOut(duration: 0.25), value: isDisabled)
    }
}

struct BottomSheetButton_Previews: PreviewProvider {
    static var previews: some View {
        BottomSheetButton(label: "Amazing button", isDisabled: false) { /* Preview */ }
        BottomSheetButton(label: "Amazing button", isDisabled: true) { /* Preview */ }
    }
}
