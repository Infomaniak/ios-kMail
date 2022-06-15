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
    // swiftlint:disable empty_count
    @ObservedResults(Folder.self, where: { $0.parentLink.count == 0 }) var folders

    @State private var selectedFolderItem: Int = 0

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
            Text("Dans quel dossier souhaitez-vous déplacer votre email ?")
                .frame(maxWidth: .infinity, alignment: .leading)
                .textStyle(.header3)
            Picker("Dossier", selection: $selectedFolderItem) {
                ForEach(sortedFolders.indices, id: \.self) { i in
                    Text(sortedFolders[i].formattedPath).tag(i)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding([.top, .bottom], 10)
            .padding([.leading, .trailing], 12)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color(hex: "#E0E0E0"))
            )
            .textStyle(.body)
            .accentColor(MailTextStyle.body.color)
            Button("Enregistrer") {
                moveHandler(sortedFolders[selectedFolderItem])
                state.close()
            }
            .textStyle(.button)
            Button("Créer un nouveau dossier") {
                // TODO: Create new folder
            }
            .textStyle(.button)
        }
        .padding([.leading, .trailing], 24)
    }
}

struct MoveEmailView_Previews: PreviewProvider {
    static var previews: some View {
        MoveEmailView(mailboxManager: MailboxManager(mailbox: PreviewHelper.sampleMailbox, apiFetcher: MailApiFetcher()),
                      state: GlobalBottomSheet()) { _ in }
    }
}
