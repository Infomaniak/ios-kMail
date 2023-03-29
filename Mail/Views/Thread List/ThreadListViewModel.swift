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
import InfomaniakCoreUI
import MailCore
import MailResources
import RealmSwift
import SwiftUI

typealias Thread = MailCore.Thread

extension Thread {
    public enum ReferenceDate: String, CaseIterable {
        case today, yesterday, thisWeek, lastWeek, thisMonth

        public var dateInterval: DateInterval {
            switch self {
            case .today:
                return .init(start: .now.startOfDay, duration: 86400)
            case .yesterday:
                return .init(start: .yesterday.startOfDay, duration: 86400)
            case .thisWeek:
                return .init(start: .now.startOfWeek, end: .now.endOfWeek)
            case .lastWeek:
                return .init(start: .lastWeek.startOfWeek, end: .lastWeek.endOfWeek)
            case .thisMonth:
                return .init(start: .now.startOfMonth, end: .now.endOfMonth)
            }
        }

        public static func titleFromRawSectionKey(_ rawKey: String) -> String {
            if let referenceDate = ReferenceDate(rawValue: rawKey) {
                return referenceDate.title
            }

            guard let timeInterval = Double(rawKey) else { return "" }
            let referenceDate = Date(timeIntervalSince1970: timeInterval)

            var formatStyle = Date.FormatStyle.dateTime.month(.wide)
            if !Calendar.current.isDate(referenceDate, equalTo: .now, toGranularity: .year) {
                formatStyle = formatStyle.year()
            }
            return referenceDate.formatted(formatStyle).capitalized
        }

        public var title: String {
            switch self {
            case .today:
                return MailResourcesStrings.Localizable.threadListSectionToday
            case .yesterday:
                return MailResourcesStrings.Localizable.messageDetailsYesterday
            case .thisWeek:
                return MailResourcesStrings.Localizable.threadListSectionThisWeek
            case .lastWeek:
                return MailResourcesStrings.Localizable.threadListSectionLastWeek
            case .thisMonth:
                return MailResourcesStrings.Localizable.threadListSectionThisMonth
            }
        }
    }

    var sectionDate: String {
        if let sectionDateInterval = (ReferenceDate.allCases.first { $0.dateInterval.contains(date) }) {
            return sectionDateInterval.rawValue
        } else {
            return "\(date.startOfMonth.timeIntervalSince1970)"
        }
    }
}

@MainActor class ThreadListViewModel: ObservableObject {
    let mailboxManager: MailboxManager

    @Published var folder: Folder?
    @Published var selectedThread: Thread?

    @Published var isLoadingPage = false
    @Published var lastUpdate: Date?

    // Used to know thread location
    private var selectedThreadIndex: Int?

    let moveSheet: MoveSheet
    let bottomSheet: ThreadBottomSheet
    var globalBottomSheet: GlobalBottomSheet?

    private var observationLastUpdateToken: NotificationToken?

    private let loadNextPageThreshold = 10

    init(
        mailboxManager: MailboxManager,
        folder: Folder?,
        bottomSheet: ThreadBottomSheet,
        moveSheet: MoveSheet
    ) {
        self.mailboxManager = mailboxManager
        self.folder = folder
        lastUpdate = folder?.lastUpdate
        self.bottomSheet = bottomSheet
        self.moveSheet = moveSheet
        observeChanges()
    }

    func fetchThreads() async {
        guard !isLoadingPage else {
            return
        }

        withAnimation {
            isLoadingPage = true
        }

        await tryOrDisplayError {
            guard let folder = folder else { return }

            try await mailboxManager.threads(folder: folder.freezeIfNeeded()) {
                Task {
                    withAnimation {
                        self.isLoadingPage = false
                    }
                }
            }
        }
        withAnimation {
            isLoadingPage = false
        }
    }

    func updateThreads(with folder: Folder) async {
        let isNewFolder = folder.id != self.folder?.id
        self.folder = folder
        withAnimation {
            lastUpdate = folder.lastUpdate
        }

        observeChanges()
        await fetchThreads()
    }

    func observeChanges(animateInitialThreadChanges: Bool = false) {
        observationLastUpdateToken?.invalidate()
        if let folder = folder?.thaw() {
            observationLastUpdateToken = folder.observe(keyPaths: [\Folder.lastUpdate], on: .main) { [weak self] changes in
                switch changes {
                case .change(let folder, _):
                    withAnimation {
                        self?.lastUpdate = folder.lastUpdate
                    }
                default:
                    break
                }
            }
        }
    }

    // MARK: - Swipe actions

    func handleSwipeAction(_ action: SwipeAction, thread: Thread) async throws {
        switch action {
        case .delete:
            try await mailboxManager.moveOrDelete(threads: [thread])
        case .archive:
            try await move(thread: thread, to: .archive)
        case .readUnread:
            try await mailboxManager.toggleRead(threads: [thread])
        case .move:
            moveSheet.state = .move(folderId: folder?.id) { folder in
                guard thread.folder != folder else { return }
                Task {
                    try await self.move(thread: thread, to: folder)
                }
            }
        case .favorite:
            try await mailboxManager.toggleStar(threads: [thread])
        case .postPone:
            // TODO: Report action
            showWorkInProgressSnackBar()
        case .spam:
            try await toggleSpam(thread: thread)
        case .quickAction:
            bottomSheet.open(state: .actions(.threads([thread.thaw() ?? thread], false)))
        case .none:
            break
        case .moveToInbox:
            try await move(thread: thread, to: .inbox)
        }
    }

    private func toggleSpam(thread: Thread) async throws {
        let destination: FolderRole = folder?.role == .spam ? .inbox : .spam
        try await move(thread: thread, to: destination)
    }

    private func move(thread: Thread, to folderRole: FolderRole) async throws {
        guard let folder = mailboxManager.getFolder(with: folderRole)?.freeze() else { return }
        try await move(thread: thread, to: folder)
    }

    private func move(thread: Thread, to folder: Folder) async throws {
        let response = try await mailboxManager.move(threads: [thread], to: folder)
        IKSnackBar.showCancelableSnackBar(message: MailResourcesStrings.Localizable.snackbarThreadMoved(folder.localizedName),
                                          cancelSuccessMessage: MailResourcesStrings.Localizable.snackbarMoveCancelled,
                                          undoRedoAction: response,
                                          mailboxManager: mailboxManager)
    }
}
