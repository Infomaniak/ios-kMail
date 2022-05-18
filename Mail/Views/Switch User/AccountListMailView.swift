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

struct AccountListMailView: View {
    var mailbox: Mailbox
    @State var isSelected = false

    var body: some View {
        HStack(spacing: 16) {
            Image(uiImage: MailResourcesAsset.envelope.image)
                .frame(width: 16, height: 16)
                
            Text(mailbox.email)
                .truncationMode(.tail)
                .lineLimit(1)

            Spacer()

            // TODO: - Replace false number
            Text("7")
                .foregroundColor(MailResourcesAsset.infomaniakColor)
        }
        .foregroundColor(isSelected ? MailResourcesAsset.infomaniakColor : MailResourcesAsset.primaryTextColor)
        .textStyle(isSelected ? .calloutStrong : .callout)
    }
}

struct AccountListMailView_Previews: PreviewProvider {
    static var previews: some View {
        AccountListMailView(mailbox: PreviewHelper.sampleMailbox)
        AccountListMailView(mailbox: PreviewHelper.sampleMailbox, isSelected: true)
    }
}
