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

struct ThreadListCell: View {
    var mailboxManager: MailboxManager
    var thread: Thread

    private var unread: Bool {
        thread.unseenMessages > 0
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .frame(width: 8, height: 8)
                .foregroundColor(Color(unread ?  MailResourcesAsset.mailPinkColor.color : .clear))
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(thread.formattedFrom)
                        .font(.system(size: 18))
                        .foregroundColor(Color(unread ? MailResourcesAsset.primaryTextColor.color : MailResourcesAsset.secondaryTextColor.color))
                        .fontWeight(unread ? .semibold : .regular)

                    Spacer()

                    if thread.hasAttachments {
                        Image(uiImage: MailResourcesAsset.attachment.image)
                    }
                    Text(thread.formattedDate)
                        .foregroundColor(Color(unread ? MailResourcesAsset.primaryTextColor.color : MailResourcesAsset.secondaryTextColor.color))
                        .fontWeight(unread ? .semibold : .regular)
                }
                .padding(.bottom, 4)

                HStack {
                    VStack(alignment: .leading) {
                        Text(thread.formattedSubject)
                            .foregroundColor(Color(unread ? MailResourcesAsset.primaryTextColor.color : MailResourcesAsset.secondaryTextColor.color))
                            .fontWeight(unread ? .semibold : .regular)
                            .lineLimit(1)

                        Text("Lorem Ipsum...")
                            .foregroundColor(Color(MailResourcesAsset.secondaryTextColor.color))
                            .lineLimit(1)
                    }

                    Spacer()

                    if thread.flagged {
                        Image(uiImage: MailResourcesAsset.starFilled.image)
                    } else {
                        Image(uiImage: MailResourcesAsset.star.image)
                            .foregroundColor(Color(unread ? MailResourcesAsset.primaryTextColor.color : MailResourcesAsset.secondaryTextColor.color))
                    }
                }
            }
        }
        .padding([.leading, .trailing], 12)
        .padding([.top, .bottom], 14)
    }
}

struct ThreadListCell_Previews: PreviewProvider {
    static var previews: some View {
        ThreadListCell(mailboxManager: MailboxManager(mailbox: PreviewHelper.sampleMailbox, apiFetcher: MailApiFetcher()), thread: PreviewHelper.sampleThread)
            .previewLayout(.sizeThatFits)
            .previewDevice("iPhone 13 Pro")
    }
}
