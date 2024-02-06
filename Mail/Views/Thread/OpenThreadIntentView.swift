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

import InfomaniakDI
import MailCore
import RealmSwift
import SwiftUI

struct OpenThreadIntentView: View, IntentViewable {
    typealias Intent = ResolvedIntent

    @LazyInjectService private var accountManager: AccountManager
    @LazyInjectService private var snackbarPresenter: SnackBarPresentable

    @Environment(\.dismiss) private var dismiss

    let resolvedIntent = State<ResolvedIntent?>()

    let openThreadIntent: OpenThreadIntent

    struct ResolvedIntent {
        let mailboxManager: MailboxManager
        let currentFolder: Folder
        let thread: Thread
        let threadObservation: NotificationToken
    }

    var body: some View {
        if let resolvedIntent = resolvedIntent.wrappedValue {
            ThreadView(thread: resolvedIntent.thread)
                .environmentObject(resolvedIntent.mailboxManager)
                .environmentObject(ActionsManager(
                    mailboxManager: resolvedIntent.mailboxManager,
                    mainViewState: MainViewState(
                        mailboxManager: resolvedIntent.mailboxManager,
                        selectedFolder: resolvedIntent.currentFolder
                    )
                ))
        } else {
            ProgressView()
                .progressViewStyle(.circular)
                .task(id: openThreadIntent) {
                    await initFromIntent()
                }
        }
    }

    func initFromIntent() async {
        guard let mailboxManager = accountManager.getMailboxManager(
            for: openThreadIntent.mailboxId,
            userId: openThreadIntent.userId
        ) else {
            dismiss()
            snackbarPresenter.show(message: MailError.unknownError.errorDescription ?? "")
            return
        }

        Task { @MainActor in
            let realm = mailboxManager.getRealm()
            guard let folder = realm.object(ofType: Folder.self, forPrimaryKey: openThreadIntent.folderId),
                  let thread = mailboxManager.getRealm().object(ofType: Thread.self, forPrimaryKey: openThreadIntent.threadUid)
            else {
                snackbarPresenter.show(message: MailError.localMessageNotFound.errorDescription ?? "")
                return
            }

            let threadObservation = thread.observe(keyPaths: [\Thread.messages]) { changeBlock in
                switch changeBlock {
                case .change(let thread, _):
                    if thread.messageInFolderCount == 0 {
                        dismiss()
                    }
                case .deleted:
                    dismiss()
                case .error:
                    break
                }
            }

            resolvedIntent.wrappedValue = ResolvedIntent(
                mailboxManager: mailboxManager,
                currentFolder: folder,
                thread: thread,
                threadObservation: threadObservation
            )
        }
    }
}

#Preview {
    OpenThreadIntentView(
        openThreadIntent: .openFromThreadCell(
            thread: PreviewHelper.sampleThread,
            currentFolder: PreviewHelper.sampleFolder,
            mailboxManager: PreviewHelper.sampleMailboxManager
        )
    )
}
