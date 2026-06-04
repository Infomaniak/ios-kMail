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

import DesignSystem
import InfomaniakCoreSwiftUI
import MailCoreUI
import MailResources
import SwiftUI

struct ThreadCellDetailsView: View {
    let hasAttachments: Bool
    let isFlagged: Bool
    let hasReminder: Bool

    var body: some View {
        HStack(spacing: IKPadding.mini) {
            if hasReminder {
                MailResourcesAsset.alarmClock
                    .iconSize(.medium)
                    .foregroundStyle(UserDefaults.shared.accentColor.primary)
                    .padding(IKPadding.micro)
                    .background(UserDefaults.shared.accentColor.secondary.swiftUIColor)
                    .cornerRadius(IKRadius.small)
            }
            if hasAttachments {
                MailResourcesAsset.attachment
                    .iconSize(.medium)
                    .foregroundStyle(MailResourcesAsset.textPrimaryColor)
            }
            if isFlagged {
                MailResourcesAsset.starFull
                    .iconSize(.medium)
                    .foregroundStyle(MailResourcesAsset.yellowColor)
            }
        }
    }
}

#Preview("Attachments, Flagged, Reminder") {
    ThreadCellDetailsView(hasAttachments: true, isFlagged: true, hasReminder: true)
}

#Preview("Attachments, Flagged, No Reminder") {
    ThreadCellDetailsView(hasAttachments: true, isFlagged: true, hasReminder: false)
}

#Preview("Attachments, Not Flagged, Reminder") {
    ThreadCellDetailsView(hasAttachments: true, isFlagged: false, hasReminder: true)
}

#Preview("Attachments Only") {
    ThreadCellDetailsView(hasAttachments: true, isFlagged: false, hasReminder: false)
}

#Preview("Flagged, Reminder, No Attachments") {
    ThreadCellDetailsView(hasAttachments: false, isFlagged: true, hasReminder: true)
}

#Preview("Flagged Only") {
    ThreadCellDetailsView(hasAttachments: false, isFlagged: true, hasReminder: false)
}

#Preview("Reminder Only") {
    ThreadCellDetailsView(hasAttachments: false, isFlagged: false, hasReminder: true)
}

#Preview("No Attachments, Not Flagged, No Reminder") {
    ThreadCellDetailsView(hasAttachments: false, isFlagged: false, hasReminder: false)
}
