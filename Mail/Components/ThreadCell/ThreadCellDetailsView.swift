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

import InfomaniakCoreSwiftUI
import MailCoreUI
import MailResources
import SwiftUI

struct ThreadCellDetailsView: View {
    let hasAttachments: Bool
    let isFlagged: Bool

    var body: some View {
        HStack(spacing: IKPadding.small) {
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

#Preview("Attachments, Flagged") {
    ThreadCellDetailsView(hasAttachments: true, isFlagged: true)
}

#Preview("Attachments, Not flagged") {
    ThreadCellDetailsView(hasAttachments: true, isFlagged: false)
}

#Preview("No Attachment, Flagged") {
    ThreadCellDetailsView(hasAttachments: false, isFlagged: true)
}

#Preview("No Attachment, Not flagged") {
    ThreadCellDetailsView(hasAttachments: false, isFlagged: false)
}
