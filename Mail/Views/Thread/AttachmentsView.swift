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
import RealmSwift
import SwiftUI

struct AttachmentsView: View {
    @ObservedObject var sheet: MessageSheet
    @EnvironmentObject var mailboxManager: MailboxManager
    @ObservedRealmObject var message: Message

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                Image(systemName: "paperclip")
                    .frame(width: 14)
                    .foregroundColor(Color(MailResourcesAsset.secondaryTextColor.color))

                Text("\(message.attachments.count) pièce jointe (\(message.attachmentsSize))")
                    .fontWeight(.regular)
                    .foregroundColor(Color(MailResourcesAsset.secondaryTextColor.color))

                Button("Tout télécharger") {
                    // TODO : after complete attachment
                }
            }
            .font(.system(size: 14))

            ScrollView(.horizontal) {
                HStack {
                    ForEach(message.attachments) { attachment in
                        AttachmentCell(attachment: attachment)
                    }
                }
            }
        }
    }
}

struct AttachmentsView_Previews: PreviewProvider {
    static var previews: some View {
        AttachmentsView(message: PreviewHelper.sampleMessage)
    }
}
