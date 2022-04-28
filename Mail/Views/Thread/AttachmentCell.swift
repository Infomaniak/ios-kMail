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
import MailResources
import SwiftUI

struct AttachmentCell: View {
    var attachment: Attachment

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 35, style: .continuous)
                .fill(Color(MailResourcesAsset.backgroundHeaderColor.color))
            Text(attachment.name)
                .truncationMode(.middle)
                .padding([.top, .bottom], 8)
                .padding([.leading, .trailing], 12)
        }
        .frame(maxWidth: 135)
        .fixedSize()
    }
}

struct AttachmentCell_Previews: PreviewProvider {
    static var previews: some View {
        AttachmentCell(attachment: PreviewHelper.sampleAttachment)
    }
}
