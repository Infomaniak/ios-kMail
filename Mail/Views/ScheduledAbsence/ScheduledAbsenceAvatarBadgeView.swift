/*
 Infomaniak Mail - iOS App
 Copyright (C) 2026 Infomaniak Network SA

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
import MailCoreUI
import MailResources
import SwiftUI

struct ScheduledAbsenceAvatarBadgeView: View {
    var body: some View {
        MailResourcesAsset.circleArrowRight.swiftUIImage
            .resizable()
            .foregroundStyle(.white)
            .background(Circle().fill(MailResourcesAsset.absenceColor.swiftUIColor))
            .frame(width: IKIconSize.medium.rawValue, height: IKIconSize.medium.rawValue)
            .accessibilityHidden(true)
    }
}

extension View {
    func scheduledAbsenceAvatarBadge(isVisible: Bool) -> some View {
        overlay(alignment: .bottomTrailing) {
            if isVisible {
                ScheduledAbsenceAvatarBadgeView()
            }
        }
    }
}

#Preview {
    Circle()
        .fill(.gray)
        .frame(width: RecipientCell.defaultAvatarSize, height: RecipientCell.defaultAvatarSize)
        .scheduledAbsenceAvatarBadge(isVisible: true)
}
