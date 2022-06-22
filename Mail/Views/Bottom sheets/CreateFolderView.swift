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

struct CreateFolderView: View {
    @StateObject var mailboxManager: MailboxManager
    @ObservedResults(Folder.self) var folders

    @State private var folderName: String = ""
    @State private var selectedFolderID: String = ""

    private var mode: Mode
    private var state: GlobalBottomSheet

    private var sortedFolders: [Folder] {
        return folders.sorted()
    }

    enum Mode {
        case create
        case move(moveHandler: (Folder) -> Void)

        var buttonTitle: String {
            switch self {
            case .create:
                return MailResourcesStrings.buttonCreate
            case .move:
                return MailResourcesStrings.actionMove
            }
        }
    }

    init(mailboxManager: MailboxManager, state: GlobalBottomSheet, mode: Mode) {
        _folders = .init(Folder.self, configuration: AccountManager.instance.currentMailboxManager?.realmConfiguration)
        _mailboxManager = StateObject(wrappedValue: mailboxManager)
        self.state = state
        self.mode = mode
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                if case let .move(moveHandler) = mode {
                    Button {
                        state.open(state: .move(moveHandler: moveHandler), position: .moveHeight)
                    } label: {
                        ChevronIcon(style: .left)
                            .padding(4)
                    }
                }
                Text(MailResourcesStrings.createFolderTitle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textStyle(.header3)
            }
            // Text field
            TextField(MailResourcesStrings.createFolderName, text: $folderName)
                .padding(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color(hex: "#E0E0E0"))
                )
                .textStyle(.body)
            // Picker
            LargePicker(title: MailResourcesStrings.createFolderParent,
                        noSelectionText: MailResourcesStrings.createFolderNoParent,
                        selection: $selectedFolderID,
                        items: sortedFolders.map { .init(id: $0.id, name: $0.formattedPath) })
            // Button
            Button(mode.buttonTitle) {
                state.close()
                Task {
                    let parent = sortedFolders.first { $0.id == selectedFolderID }
                    await tryOrDisplayError {
                        let folder = try await mailboxManager.createFolder(name: folderName, parent: parent)
                        if case let .move(moveHandler) = mode {
                            moveHandler(folder)
                        }
                    }
                }
            }
            .textStyle(.button)
        }
        .padding([.leading, .trailing], 24)
    }
}

struct CreateFolderView_Previews: PreviewProvider {
    static var previews: some View {
        CreateFolderView(mailboxManager: MailboxManager(mailbox: PreviewHelper.sampleMailbox, apiFetcher: MailApiFetcher()), state: GlobalBottomSheet(), mode: .create)
        CreateFolderView(mailboxManager: MailboxManager(mailbox: PreviewHelper.sampleMailbox, apiFetcher: MailApiFetcher()), state: GlobalBottomSheet(), mode: .move { _ in })
    }
}
