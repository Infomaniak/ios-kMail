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

struct MoveEmailView: View {
    @StateObject var mailboxManager: MailboxManager
    @ObservedResults(Folder.self) var folders

    @State private var selectedFolderID: String = ""

    private let state: GlobalBottomSheet
    private let moveHandler: (Folder) -> Void

    private var sortedFolders: [Folder] {
        return folders.sorted()
    }

    init(mailboxManager: MailboxManager, state: GlobalBottomSheet, moveHandler: @escaping (Folder) -> Void) {
        _folders = .init(Folder.self, configuration: AccountManager.instance.currentMailboxManager?.realmConfiguration)
        _mailboxManager = StateObject(wrappedValue: mailboxManager)
        self.state = state
        self.moveHandler = moveHandler
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 16) {
            Text(MailResourcesStrings.Localizable.moveTitle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textStyle(.header3)
            LargePicker(selection: $selectedFolderID, items: sortedFolders.map { .init(id: $0.id, name: $0.formattedPath) })
            Button(MailResourcesStrings.Localizable.actionMove) {
                moveHandler(sortedFolders.first { $0.id == selectedFolderID }!)
                state.close()
            }
            .textStyle(.button)
            Button(MailResourcesStrings.Localizable.buttonCreateFolder) {
                state.open(state: .createNewFolder(mode: .move(moveHandler: moveHandler)), position: .newFolderHeight)
            }
            .textStyle(.button)
        }
        .padding([.leading, .trailing], 24)
        .onAppear {
            selectedFolderID = sortedFolders.first?.id ?? ""
        }
    }
}

struct MoveEmailView_Previews: PreviewProvider {
    static var previews: some View {
        MoveEmailView(mailboxManager: PreviewHelper.sampleMailboxManager,
                      state: GlobalBottomSheet()) { _ in }
    }
}
