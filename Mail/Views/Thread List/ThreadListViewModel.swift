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

class DateSection: Identifiable {
    enum ReferenceDate {
        case today, month, older(Date)

        public var dateInterval: DateInterval {
            switch self {
            case .today:
                return .init(start: .now.startOfDay, end: .now.endOfDay)
            case .month:
                return .init(start: .now.startOfMonth, end: .now.endOfMonth)
            case let .older(date):
                return .init(start: date.startOfMonth, end: date.endOfMonth)
            }
        }
    }

    var id: DateInterval { referenceDate.dateInterval }
    var title: String {
        switch referenceDate {
        case .today:
            return MailResourcesStrings.Localizable.threadListSectionToday
        case .month:
            return MailResourcesStrings.Localizable.threadListSectionThisMonth
        case let .older(date):
            var formatStyle = Date.FormatStyle.dateTime.month(.wide)
            if !Calendar.current.isDate(date, equalTo: .now, toGranularity: .year) {
                formatStyle = formatStyle.year()
            }
            return date.formatted(formatStyle).capitalized
        }
    }

    var threads = [Thread]()

    private var referenceDate: ReferenceDate

    init(thread: Thread) {
        if Calendar.current.isDateInToday(thread.date) {
            referenceDate = .today
        } else if Calendar.current.isDate(thread.date, equalTo: .now, toGranularity: .month) {
            referenceDate = .month
        } else {
            referenceDate = .older(thread.date)
        }
    }

    func threadBelongsToSection(thread: Thread) -> Bool {
        switch referenceDate {
        case .today:
            return Calendar.current.isDateInToday(thread.date)
        case .month:
            return Calendar.current.isDate(thread.date, equalTo: .now, toGranularity: .month)
        case let .older(date):
            return Calendar.current.isDate(thread.date, equalTo: date, toGranularity: .month)
        }
    }
}

@MainActor class ThreadListViewModel: ObservableObject {
    let mailboxManager: MailboxManager

    @Published var folder: Folder?
    @Published var sections = [DateSection]()
    @Published var selectedThread: Thread?
    @Published var isLoadingPage = false
    @Published var lastUpdate: Date?

    let moveSheet: MoveSheet
    let bottomSheet: ThreadBottomSheet
    var globalBottomSheet: GlobalBottomSheet?

    var scrollViewProxy: ScrollViewProxy?

    private var observationThreadToken: NotificationToken?
    private var observationLastUpdateToken: NotificationToken?

    @Published var filter = Filter.all {
        didSet {
            Task {
                observeChanges(animateInitialThreadChanges: true)
                if let topThread = sections.first?.threads.first?.id {
                    withAnimation {
                        self.scrollViewProxy?.scrollTo(topThread, anchor: .top)
                    }
                }
            }
        }
    }

    var filterUnreadOn: Bool {
        get {
            return filter == .unseen
        }
        set {
            filter = newValue ? .unseen : .all
        }
    }

    private let loadNextPageThreshold = 10

    init(mailboxManager: MailboxManager, folder: Folder?, bottomSheet: ThreadBottomSheet, moveSheet: MoveSheet) {
        self.mailboxManager = mailboxManager
        self.folder = folder
        lastUpdate = folder?.lastUpdate
        self.bottomSheet = bottomSheet
        self.moveSheet = moveSheet
        observeChanges()
        if let folder {
            sortThreadsIntoSections(threads: Array(folder.threads.sorted(by: \.date, ascending: false).freezeIfNeeded()))
        }
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

            try await mailboxManager.threads(folder: folder.freezeIfNeeded())
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

        if isNewFolder && filter != .all {
            filter = .all
        } else {
            observeChanges()
            await fetchThreads()
        }
    }

    func observeChanges(animateInitialThreadChanges: Bool = false) {
        observationThreadToken?.invalidate()
        observationLastUpdateToken?.invalidate()
        if let folder = folder?.thaw() {
            let threadResults = folder.threads.sorted(by: \.date, ascending: false)
            observationThreadToken = threadResults.observe(on: .main) { [weak self] changes in
                switch changes {
                case let .initial(results):
                    withAnimation(animateInitialThreadChanges ? .default : nil) {
                        self?.sortThreadsIntoSections(threads: Array(results.freezeIfNeeded()))
                    }
                case let .update(results, _, _, _):
                    if self?.filter != .all && results.count == 1 && self?.filter.accepts(thread: results[0]) != true {
                        self?.filter = .all
                    }
                    withAnimation {
                        self?.sortThreadsIntoSections(threads: Array(results.freezeIfNeeded()))
                    }
                case .error:
                    break
                }
            }
            observationLastUpdateToken = folder.observe(keyPaths: [\Folder.lastUpdate], on: .main) { [weak self] changes in
                switch changes {
                case let .change(folder, _):
                    withAnimation {
                        self?.lastUpdate = folder.lastUpdate
                    }
                default:
                    break
                }
            }
        } else {
            sections = []
        }
    }

    func sortThreadsIntoSections(threads: [Thread]) {
        var newSections = [DateSection]()

        var currentSection: DateSection?
        let filteredThreads = threads.filter { $0.id == selectedThread?.id || filter.accepts(thread: $0) }
        if filteredThreads.isEmpty && filterUnreadOn {
            filterUnreadOn.toggle()
        } else {
            for thread in filteredThreads {
                if currentSection?.threadBelongsToSection(thread: thread) != true {
                    currentSection = DateSection(thread: thread)
                    newSections.append(currentSection!)
                }
                currentSection?.threads.append(thread)
            }

            sections = newSections
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
                guard thread.folderId != folder.id else { return }
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
        case .readAndArchive:
            if thread.hasUnseenMessages {
                try await mailboxManager.toggleRead(threads: [thread])
            }
            try await move(thread: thread, to: .archive)
        case .quickAction:
            bottomSheet.open(state: .actions(.threads([thread.thaw() ?? thread])))
        case .none:
            break
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
