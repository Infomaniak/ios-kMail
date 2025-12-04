/*
 Infomaniak Mail - iOS App
 Copyright (C) 2023 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import RealmSwift
import SwiftModalPresentation
import SwiftUI

struct MoveEmailView: View {
    typealias MoveHandler = (Folder) -> Void

    @Environment(\.dismissModal) private var dismissModal
    @EnvironmentObject private var actionsManager: ActionsManager

    @StateObject private var viewModel: FolderListViewModel

    @ModalState(context: ContextKeys.moveEmail) private var isShowingCreateFolderAlert = false

    let movedMessages: [Message]
    let originFolder: Folder?
    let completion: ((Action) -> Void)?

    init(mailboxManager: MailboxManager, movedMessages: [Message], originFolder: Folder?, completion: ((Action) -> Void)? = nil) {
        self.movedMessages = movedMessages
        self.originFolder = originFolder
        self.completion = completion
        _viewModel =
            StateObject(wrappedValue: FolderListViewModel(mailboxManager: mailboxManager) { $0.isAcceptingMove })
    }

    var body: some View {
        SearchableFolderListView(
            viewModel: viewModel,
            originFolderId: originFolder?.remoteId,
            customCompletion: move
        )
        .navigationTitle(MailResourcesStrings.Localizable.actionMove)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    @InjectService var matomo: MatomoUtils
                    matomo.track(eventWithCategory: .createFolder, name: "fromMove")
                    isShowingCreateFolderAlert.toggle()
                } label: {
                    MailResourcesAsset.folderAdd.swiftUIImage
                }
            }
        }
        .matomoView(view: ["MoveEmailView"])
        .mailCustomAlert(isPresented: $isShowingCreateFolderAlert) {
            CreateFolderView(mode: .move { newFolder in
                move(to: newFolder)
            })
        }
    }

    private func move(to folder: Folder) {
        let frozenOriginFolder = originFolder?.freezeIfNeeded()
        let frozenDestinationFolder = folder.freezeIfNeeded()

        Task {
            await tryOrDisplayError {
                try await actionsManager.performMove(
                    messages: movedMessages,
                    from: frozenOriginFolder,
                    to: frozenDestinationFolder
                )

                completion?(.moved)
            }
        }
        dismissModal()
    }
}

#Preview {
    MoveEmailView(
        mailboxManager: PreviewHelper.sampleMailboxManager,
        movedMessages: [PreviewHelper.sampleMessage],
        originFolder: nil
    )
    .environmentObject(PreviewHelper.sampleMailboxManager)
}
