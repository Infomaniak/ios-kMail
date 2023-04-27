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
        case today, yesterday, thisWeek, lastWeek, thisMonth, older(Date)

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
            case .older(let date):
                return .init(start: date.startOfMonth, end: date.endOfMonth)
            }
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
            case .older(let date):
                var formatStyle = Date.FormatStyle.dateTime.month(.wide)
                if !Calendar.current.isDate(date, equalTo: .now, toGranularity: .year) {
                    formatStyle = formatStyle.year()
                }
                return date.formatted(formatStyle).capitalized
            }
        }
    }

    let id: DateInterval
    let title: String
    var threads = [Thread]()

    private let referenceDate: ReferenceDate

    init(thread: Thread) {
        let sections: [ReferenceDate] = [.today, .yesterday, .thisWeek, .lastWeek, .thisMonth]
        referenceDate = sections.first { $0.dateInterval.contains(thread.date) } ?? .older(thread.date)
        id = referenceDate.dateInterval
        title = referenceDate.title
    }

    func threadBelongsToSection(thread: Thread) -> Bool {
        return referenceDate.dateInterval.contains(thread.date)
    }
}

@MainActor class ThreadListViewModel: ObservableObject {
    let mailboxManager: MailboxManager

    @Published var folder: Folder
    @Published var sections = [DateSection]()
    @Published var selectedThread: Thread? {
        didSet {
            selectedThreadIndex = filteredThreads.firstIndex { $0.uid == selectedThread?.uid }
        }
    }

    @Published var isLoadingPage = false
    @Published var lastUpdate: Date?
    @Published var actionsTarget: ActionsTarget?

    // Used to know thread location
    private var selectedThreadIndex: Int?
    var filteredThreads = [Thread]() {
        didSet {
            guard let thread = selectedThread,
                  let index = filteredThreads.firstIndex(where: { $0.uid == thread.uid }) else { return }
            selectedThreadIndex = index
        }
    }

    let moveSheet: MoveSheet

    var scrollViewProxy: ScrollViewProxy?
    var isCompact: Bool

    private var observationThreadToken: NotificationToken?
    private var observationLastUpdateToken: NotificationToken?
    private let observeQueue = DispatchQueue(label: "com.infomaniak.thread-results", qos: .userInteractive)

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

    init(
        mailboxManager: MailboxManager,
        folder: Folder,
        moveSheet: MoveSheet,
        isCompact: Bool
    ) {
        self.mailboxManager = mailboxManager
        self.folder = folder
        lastUpdate = folder.lastUpdate
        self.moveSheet = moveSheet
        self.isCompact = isCompact
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
        let isNewFolder = folder.id != self.folder.id
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
        guard let folder = folder.thaw() else {
            sections = []
            return
        }

        let threadResults: Results<Thread>
        if let predicate = filter.predicate {
            threadResults = folder.threads.filter(predicate + " OR uid == %@", selectedThread?.uid ?? "")
                .sorted(by: \.date, ascending: false)
        } else {
            threadResults = folder.threads.sorted(by: \.date, ascending: false)
        }

        observationThreadToken = threadResults.observe(on: observeQueue) { [weak self] changes in
            switch changes {
            case .initial(let results):
                let filteredThreads = Array(results.freezeIfNeeded())
                guard let newSections = self?.sortThreadsIntoSections(threads: filteredThreads) else { return }

                DispatchQueue.main.sync {
                    self?.filteredThreads = filteredThreads
                    withAnimation(animateInitialThreadChanges ? .default : nil) {
                        self?.sections = newSections
                    }
                }
            case .update(let results, _, _, _):
                let filteredThreads = Array(results.freezeIfNeeded())
                guard let newSections = self?.sortThreadsIntoSections(threads: filteredThreads) else { return }

                DispatchQueue.main.sync {
                    self?.nextThreadIfNeeded(from: filteredThreads)
                    self?.filteredThreads = filteredThreads
                    if self?.filter != .all && filteredThreads.count == 1
                        && self?.filter.accepts(thread: filteredThreads[0]) != true {
                        self?.filter = .all
                    }
                    withAnimation {
                        self?.sections = newSections
                    }
                }
            case .error:
                break
            }
        }
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

    func nextThreadIfNeeded(from threads: [Thread]) {
        guard !isCompact,
              !threads.contains(where: { $0.uid == selectedThread?.uid }),
              let lastIndex = selectedThreadIndex else { return }
        let validIndex = min(lastIndex, threads.count - 1)
        selectedThread = threads[validIndex]
    }

    private func sortThreadsIntoSections(threads: [Thread]) -> [DateSection]? {
        var newSections = [DateSection]()

        var currentSection: DateSection?
        if threads.isEmpty && filterUnreadOn {
            DispatchQueue.main.sync {
                filterUnreadOn.toggle()
            }
            return nil
        } else {
            for thread in threads {
                if currentSection?.threadBelongsToSection(thread: thread) != true {
                    currentSection = DateSection(thread: thread)
                    newSections.append(currentSection!)
                }
                currentSection?.threads.append(thread)
            }

            return newSections
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
            moveSheet.state = .move(folderId: folder.id) { folder in
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
            actionsTarget = .threads([thread.thaw() ?? thread], false)
        case .none:
            break
        case .moveToInbox:
            try await move(thread: thread, to: .inbox)
        }
    }

    private func toggleSpam(thread: Thread) async throws {
        let destination: FolderRole = folder.role == .spam ? .inbox : .spam
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
