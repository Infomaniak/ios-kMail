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
import SwiftUI

struct ThreadCellAvatarCheckboxView: View {
    @EnvironmentObject private var mailboxManager: MailboxManager

    let accentColor: AccentColor
    let density: ThreadDensity
    let isSelected: Bool
    let isMultipleSelectionEnabled: Bool
    let shouldDisplayCheckbox: Bool
    let contactConfiguration: ContactConfiguration
    let avatarTapped: (() -> Void)?

    var body: some View {
        Group {
            if density == .large {
                ZStack {
                    AvatarView(mailboxManager: mailboxManager, contactConfiguration: contactConfiguration, size: 40)
                        .opacity(isSelected ? 0 : 1)
                        .onTapGesture {
                            avatarTapped?()
                        }
                    CheckboxView(isSelected: isSelected, density: density, accentColor: accentColor)
                        .opacity(isSelected ? 1 : 0)
                }
                .accessibility(hidden: true)
                .animation(nil, value: isSelected)
            } else if isMultipleSelectionEnabled {
                CheckboxView(isSelected: isSelected, density: density, accentColor: accentColor)
                    .opacity(shouldDisplayCheckbox ? 1 : 0)
                    .animation(.default.speed(1.5), value: shouldDisplayCheckbox)
            }
        }
    }
}

#Preview {
    ThreadCellAvatarCheckboxView(
        accentColor: .pink,
        density: .large,
        isSelected: false,
        isMultipleSelectionEnabled: false,
        shouldDisplayCheckbox: true,
        contactConfiguration: .emptyContact,
        avatarTapped: nil
    )
}
