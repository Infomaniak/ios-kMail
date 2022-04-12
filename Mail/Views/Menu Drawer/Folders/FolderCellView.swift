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

struct FolderCellView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var accountManager: AccountManager

    @State var folder: Folder
    @State private var shouldNavigate = false

    @Binding var selectedFolderId: String?

    var icon: MailResourcesImages
    var isCompact: Bool
    var isUserFolder = false
    var usePadding = true

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
                CellContentView(selectedFolderId: $selectedFolderId, folder: $folder, icon: icon, isUserFolder: isUserFolder)
            }
        }
        .padding([.top, .bottom], usePadding ? 4 : 0)
    }

    private func updateSplitView(with folder: Folder, dismiss: Bool = true) {
        delegate?.didSelectFolder(folder, mailboxManager: accountManager.currentMailboxManager)
        if dismiss {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

private struct CellContentView: View {
    @Binding var selectedFolderId: String?
    @Binding var folder: Folder

    var icon: MailResourcesImages
    var isUserFolder: Bool

    private var iconSize: CGFloat {
        if isUserFolder {
            return folder.isFavorite ? 22 : 19
        }
        return 24
    }

    private var isSelected: Bool {
        folder.id == selectedFolderId
    }

    var body: some View {
        HStack {
            Image(uiImage: icon.image)
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
        FolderCellView(folder: PreviewHelper.sampleFolder,
                       selectedFolderId: .constant("blabla"),
                       icon: MailResourcesAsset.drawer,
                       isCompact: false)
        .previewLayout(.sizeThatFits)
        .previewDevice(PreviewDevice(stringLiteral: "iPhone 11 Pro"))
    }
}
