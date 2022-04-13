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

protocol FolderListViewDelegate: AnyObject {
    func didSelectFolder(_ folder: Folder, mailboxManager: MailboxManager?)
}

struct FolderCell: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var accountManager: AccountManager

    @State var folder: Folder
    @State private var shouldNavigate = false

    @Binding var selectedFolderId: String?

    var isCompact: Bool

    weak var delegate: FolderListViewDelegate?

    var body: some View {
        VStack {
            if !isCompact {
                NavigationLink(destination: ThreadList(mailboxManager: accountManager.currentMailboxManager!, folder: folder, isCompact: isCompact), isActive: $shouldNavigate) {
                    EmptyView()
                }
            }

            Button {
                updateSplitView(with: folder)
                selectedFolderId = folder.id
                shouldNavigate = true
            } label: {
                FolderCellContentView(selectedFolderId: $selectedFolderId, folder: $folder)
            }
        }
    }

    private func updateSplitView(with folder: Folder) {
        delegate?.didSelectFolder(folder, mailboxManager: accountManager.currentMailboxManager)
        presentationMode.wrappedValue.dismiss()
    }
}

private struct FolderCellContentView: View {
    @Binding var selectedFolderId: String?
    @Binding var folder: Folder

    private var iconSize: CGFloat {
        if folder.role == nil {
            return folder.isFavorite ? 22 : 19
        }
        return 24
    }

    private var isSelected: Bool {
        folder.id == selectedFolderId
    }

    var body: some View {
        HStack {
            folder.icon
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .foregroundColor(Color(InfomaniakCoreAsset.infomaniakColor.color))
                .padding(.trailing, 10)

            Text(folder.localizedName)
                .foregroundColor(Color(isSelected ? InfomaniakCoreAsset.infomaniakColor.color : MailResourcesAsset.primaryTextColor.color))
                .fontWeight(isSelected ? .semibold : .regular)

            Spacer()

            if let unreadCount = folder.unreadCount, unreadCount > 0 {
                Text(unreadCount < 100 ? "\(unreadCount)" : "99+")
                    .foregroundColor(Color(InfomaniakCoreAsset.infomaniakColor.color))
                    .fontWeight(isSelected ? .semibold : .regular)
            }
        }
    }
}

struct FolderCellView_Previews: PreviewProvider {
    static var previews: some View {
        FolderCell(folder: PreviewHelper.sampleFolder,
                       selectedFolderId: .constant("blabla"),
                       isCompact: false)
        .previewLayout(.sizeThatFits)
        .previewDevice(PreviewDevice(stringLiteral: "iPhone 11 Pro"))
    }
}
