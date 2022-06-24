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

import Foundation
import InfomaniakCore
import MailCore
import MailResources
import RealmSwift
import SwiftUI

typealias Thread = MailCore.Thread

@MainActor class ThreadListViewModel: ObservableObject {
    var mailboxManager: MailboxManager

    @Published var folder: Folder?
    @Published var threads: [Thread] = []
    @Published var isLoadingPage = false

    var bottomSheet: ThreadBottomSheet
    var globalBottomSheet: GlobalBottomSheet?

    private var resourceNext: String?
    private var observationThreadToken: NotificationToken?

    var filter = Filter.all {
        didSet {
            Task {
                await fetchThreads()
            }
        }
    }

    init(mailboxManager: MailboxManager, folder: Folder?, bottomSheet: ThreadBottomSheet) {
        self.mailboxManager = mailboxManager
        self.folder = folder
        self.bottomSheet = bottomSheet
        observeChanges()
    }

    func fetchThreads() async {
        guard !isLoadingPage else {
            return
        }

        isLoadingPage = true

        await tryOrDisplayError {
            guard let folder = folder else { return }
            let result = try await mailboxManager.threads(folder: folder.freezeIfNeeded(), filter: filter)
            resourceNext = result.resourceNext
        }
        isLoadingPage = false
        mailboxManager.draftOffline()
    }

    func fetchNextPage() async {
        guard !isLoadingPage, let resource = resourceNext else {
            return
        }

        isLoadingPage = true

        await tryOrDisplayError {
            guard let folder = folder else { return }
            let result = try await mailboxManager.threads(folder: folder.freezeIfNeeded(), resource: resource)
            resourceNext = result.resourceNext
        }
        isLoadingPage = false
        mailboxManager.draftOffline()
    }

    func updateThreads(with folder: Folder) {
        self.folder = folder
        observeChanges()

        Task {
            await self.fetchThreads()
        }
    }

    func observeChanges() {
        observationThreadToken?.invalidate()
        if let folder = folder?.thaw() {
            let threadResults = folder.threads.sorted(by: \.date, ascending: false)
            observationThreadToken = threadResults.observe(on: .main) { [weak self] changes in
                switch changes {
                case let .initial(results):
                    self?.threads = Array(results.freezeIfNeeded())
                case let .update(results, _, _, _):
                    withAnimation {
                        self?.threads = Array(results.freezeIfNeeded())
                    }
                case .error:
                    break
                }
            }
        } else {
            threads = []
        }
    }

    func loadNextPageIfNeeded(currentItem: Thread) {
        // Start loading next page when we reach the second-to-last item
        guard !threads.isEmpty else { return }
        let thresholdIndex = threads.index(threads.endIndex, offsetBy: -1)
        if threads.firstIndex(where: { $0.uid == currentItem.uid }) == thresholdIndex {
            Task {
                await fetchNextPage()
            }
        }
    }

    // MARK: - Swipe actions

    func hanldeSwipeAction(_ action: SwipeAction, thread: Thread) async {
        await tryOrDisplayError {
            switch action {
            case .delete:
                try await mailboxManager.moveOrDelete(thread: thread)
            case .archive:
                try await move(thread: thread, to: .archive)
            case .readUnread:
                try await mailboxManager.toggleRead(thread: thread)
            case .move:
                globalBottomSheet?.open(state: .move(moveHandler: { folder in
                    print("FOLDER \(folder.name)")
                }), position: .moveHeight)
            case .favorite:
                try await mailboxManager.toggleStar(thread: thread)
            case .report:
                // TODO: Report action
                break
            case .spam:
                try await toggleSpam(thread: thread)
            case .readAndAchive:
                if thread.unseenMessages > 0 {
                    try await mailboxManager.toggleRead(thread: thread)
                }
                try await move(thread: thread, to: .archive)
            case .quickAction:
                bottomSheet.open(state: .actions(.thread(thread.thaw() ?? thread)), position: .middle)
            case .none:
                break
            }
        }
    }

    private func toggleSpam(thread: Thread) async throws {
        let folderRole: FolderRole
        let response: UndoResponse
        if folder?.role == .spam {
            response = try await mailboxManager.nonSpam(thread: thread)
            folderRole = .inbox
        } else {
            response = try await mailboxManager.reportSpam(thread: thread)
            folderRole = .spam
        }
        IKSnackBar.showCancelableSnackBar(message: MailResourcesStrings.snackbarThreadMoved(folderRole.localizedName),
                                          cancelSuccessMessage: MailResourcesStrings.snackbarMoveCancelled,
                                          cancelableResponse: response,
                                          mailboxManager: mailboxManager)
    }

    private func move(thread: Thread, to folderRole: FolderRole) async throws {
        let response = try await mailboxManager.move(thread: thread, to: folderRole)
        IKSnackBar.showCancelableSnackBar(message: MailResourcesStrings.snackbarThreadMoved(folderRole.localizedName),
                                          cancelSuccessMessage: MailResourcesStrings.snackbarMoveCancelled,
                                          cancelableResponse: response,
                                          mailboxManager: mailboxManager)
    }
}
