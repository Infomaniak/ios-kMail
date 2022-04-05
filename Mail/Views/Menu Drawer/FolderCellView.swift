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

import InfomaniakCore
import MailCore
import MailResources
import SwiftUI

struct FolderCellView: View {
    var mailboxManager: MailboxManager
    @State var folder: Folder

    var icon: MailResourcesImages
    var action: (Folder) -> Void

    var body: some View {
        NavigationLink(destination: ThreadList(mailboxManager: mailboxManager, folder: folder)) {
            HStack {
                Image(uiImage: icon.image)
                    .foregroundColor(Color(InfomaniakCoreAsset.infomaniakColor.color))

                Text(folder.localizedName)
                    .foregroundColor(Color(MailResourcesAsset.primaryTextColor.color))

                Spacer()

                if let unreadCount = folder.unreadCount, unreadCount > 0 {
                    Text(unreadCount < 100 ? "\(unreadCount)" : "99+")
                        .foregroundColor(Color(InfomaniakCoreAsset.infomaniakColor.color))
                }
            }
        }
    }
}

struct FolderCellView_Previews: PreviewProvider {
    static var previews: some View {
        FolderCellView(mailboxManager: MailboxManager(mailbox: PreviewHelper.sampleMailbox, apiFetcher: MailApiFetcher()), folder: PreviewHelper.sampleFolder, icon: MailResourcesAsset.drawer) { _ in
            print("Hello")
        }
        .previewLayout(.sizeThatFits)
    }
}
