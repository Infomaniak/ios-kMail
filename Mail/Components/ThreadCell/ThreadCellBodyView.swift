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

import MailCore
import MailResources
import SwiftUI

struct ThreadCellBodyView: View, Equatable {
    let subject: String
    let preview: String
    let density: ThreadDensity
    let folderName: String?

    let answered: Bool
    let forwarded: Bool
    let hasAttachments: Bool
    let isFlagged: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: UIPadding.verySmall) {
            if density == .compact {
                HStack(spacing: UIPadding.verySmall) {
                    ThreadCellAnsweredView(answered: answered, forwarded: forwarded)
                    ThreadCellTextView(text: subject, type: .subject)
                    MessageFolderTag(title: folderName)
                    ThreadCellDetailsView(hasAttachments: hasAttachments, isFlagged: isFlagged)
                }
            } else {
                HStack(spacing: UIPadding.verySmall) {
                    ThreadCellAnsweredView(answered: answered, forwarded: forwarded)
                    ThreadCellTextView(text: subject, type: .subject)
                    ThreadCellDetailsView(hasAttachments: hasAttachments, isFlagged: isFlagged)
                }

                HStack(spacing: UIPadding.verySmall) {
                    ThreadCellTextView(text: preview, type: .preview)
                    MessageFolderTag(title: folderName)
                }
            }
        }
    }
}
