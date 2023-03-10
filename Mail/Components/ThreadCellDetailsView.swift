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

struct ThreadCellDetailsView: View {
    let thread: Thread
    var body: some View {
        HStack(spacing: 8) {
            if thread.hasAttachments {
                Image(resource: MailResourcesAsset.attachment)
                    .resizable()
                    .foregroundColor(MailResourcesAsset.textPrimaryColor)
                    .scaledToFit()
                    .frame(height: 16)
            }
            if thread.flagged {
                Image(resource: MailResourcesAsset.starFull)
                    .resizable()
                    .foregroundColor(MailResourcesAsset.yellowActionColor)
                    .scaledToFit()
                    .frame(width: 16, height: 16)
            }
        }
    }
}
