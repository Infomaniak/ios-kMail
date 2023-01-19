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
    @FocusState private var isFocused

    private var mode: Mode
    private var state: GlobalAlert

    private var sortedFolders: [Folder] {
        return folders.sorted()
    }

    enum Mode {
        case create
        case move(moveHandler: MoveSheet.MoveHandler)

        var buttonTitle: String {
            switch self {
            case .create:
                return MailResourcesStrings.Localizable.buttonCreate
            case .move:
                return MailResourcesStrings.Localizable.actionMove
            }
        }
    }

    init(mailboxManager: MailboxManager, state: GlobalAlert, mode: Mode) {
        _folders = .init(Folder.self, configuration: AccountManager.instance.currentMailboxManager?.realmConfiguration)
        _mailboxManager = StateObject(wrappedValue: mailboxManager)
        self.state = state
        self.mode = mode
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 16) {
            // Header
            Text(MailResourcesStrings.Localizable.createFolderTitle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textStyle(.bodyMedium)
            // Text field
            TextField(MailResourcesStrings.Localizable.createFolderName, text: $folderName)
                .padding(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color(hex: "#E0E0E0"))
                )
                .textStyle(.body)
                .focused($isFocused)
            // Button
            BottomSheetButtonsView(primaryButtonTitle: mode.buttonTitle,
                                   secondaryButtonTitle: MailResourcesStrings.Localizable.buttonCancel) {
                state.state = nil
                Task {
                    let parent = sortedFolders.first { $0.id == selectedFolderID }
                    await tryOrDisplayError {
                        let folder = try await mailboxManager.createFolder(name: folderName, parent: parent)
                        if case let .move(moveHandler) = mode {
                            moveHandler(folder)
                            NotificationCenter.default.post(Notification(name: Constants.dismissMoveSheetNotificationName))
                        }
                    }
                }
            } secondaryButtonAction: {
                state.state = nil
            }
        }
        .onAppear {
            isFocused = true
        }
    }
}

struct CreateFolderView_Previews: PreviewProvider {
    static var previews: some View {
        CreateFolderView(mailboxManager: PreviewHelper.sampleMailboxManager, state: GlobalAlert(), mode: .create)
        CreateFolderView(mailboxManager: PreviewHelper.sampleMailboxManager, state: GlobalAlert(), mode: .move { _ /* Preview */ in })
    }
}
