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
    @ObservedResults(Folder.self, where: { $0.toolType == nil }) var folders

    @State private var selectedFolderID: String = ""

    private let state: GlobalBottomSheet
    private let globalAlert: GlobalAlert
    private let moveHandler: (Folder) -> Void

    private var sortedFolders: [Folder] {
        return folders.sorted()
    }

    init(mailboxManager: MailboxManager, currentFolderId: String?, state: GlobalBottomSheet, globalAlert: GlobalAlert, moveHandler: @escaping (Folder) -> Void) {
        _folders = .init(Folder.self, configuration: AccountManager.instance.currentMailboxManager?.realmConfiguration) {
            $0.id != currentFolderId ?? "" && $0.toolType == nil
        }
        _mailboxManager = StateObject(wrappedValue: mailboxManager)
        self.state = state
        self.globalAlert = globalAlert
        self.moveHandler = moveHandler
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 24) {
            Text(MailResourcesStrings.Localizable.moveTitle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textStyle(.header4)
            Image(resource: MailResourcesAsset.moveIllu)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 400)
            LargePicker(
                selection: $selectedFolderID,
                items: sortedFolders.map { .init(id: $0.id, name: $0.formattedPath) },
                button: Button {
                    state.close()
                    globalAlert.state = .createNewFolder(mode: .move(moveHandler: moveHandler))
                } label: {
                    Label {
                        Text(MailResourcesStrings.Localizable.buttonCreateFolder)
                    } icon: {
                        Image(resource: MailResourcesAsset.add)
                    }
                }
            )
            BottomSheetButtonsView(primaryButtonTitle: MailResourcesStrings.Localizable.actionMove,
                                   secondaryButtonTitle: MailResourcesStrings.Localizable.buttonCancel) {
                moveHandler(sortedFolders.first { $0.id == selectedFolderID }!)
                state.close()
            } secondaryButtonAction: {
                state.close()
            }
        }
        .padding(.horizontal, Constants.bottomSheetHorizontalPadding)
        .onAppear {
            selectedFolderID = sortedFolders.first?.id ?? ""
        }
    }
}

struct MoveEmailView_Previews: PreviewProvider {
    static var previews: some View {
        MoveEmailView(mailboxManager: PreviewHelper.sampleMailboxManager,
                      currentFolderId: "",
                      state: GlobalBottomSheet(),
                      globalAlert: GlobalAlert()) { _ /* Preview */ in }
    }
}
