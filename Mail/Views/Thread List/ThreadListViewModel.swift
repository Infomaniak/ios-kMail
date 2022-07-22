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

class DateSection: Identifiable {
    enum ReferenceDate {
        case today, month, older(Date)

        public var dateInterval: DateInterval {
            switch self {
            case .today:
                return .init(start: .now.startOfDay, end: .now.endOfDay)
            case .month:
                return .init(start: .now.startOfMonth, end: .now.endOfMonth)
            case .older(let date):
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
    var mailboxManager: MailboxManager

    @Published var folder: Folder?
    @Published var sections = [DateSection]()
    @Published var selectedThread: Thread?
    @Published var isLoadingPage = false
    @Published var lastUpdate: Date?

    var bottomSheet: ThreadBottomSheet
    var globalBottomSheet: GlobalBottomSheet?
    var menuSheet: MenuSheet?

    private var resourceNext: String?
    private var observationThreadToken: NotificationToken?
    private var observationLastUpdateToken: NotificationToken?

    @Published var filter = Filter.all {
        didSet {
            Task {
                await fetchThreads()
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

    init(mailboxManager: MailboxManager, folder: Folder?, bottomSheet: ThreadBottomSheet) {
        self.mailboxManager = mailboxManager
        self.folder = folder
        lastUpdate = folder?.lastUpdate
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
        withAnimation {
            lastUpdate = folder.lastUpdate
        }
        observeChanges()

        Task {
            await self.fetchThreads()
        }
    }

    func observeChanges() {
        observationThreadToken?.invalidate()
        observationLastUpdateToken?.invalidate()
        if let folder = folder?.thaw() {
            let threadResults = folder.threads.sorted(by: \.date, ascending: false)
            observationThreadToken = threadResults.observe(on: .main) { [weak self] changes in
                switch changes {
                case let .initial(results):
                    self?.sortThreadsIntoSections(threads: Array(results.freezeIfNeeded()))
                case let .update(results, _, _, _):
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

    func loadNextPageIfNeeded(currentItem: Thread) {
        // Start loading next page when we reach the second-to-last item
        let threads = sections.flatMap(\.threads)
        guard threads.count > loadNextPageThreshold else { return }
        let thresholdIndex = threads.index(threads.endIndex, offsetBy: -loadNextPageThreshold)
        if threads.firstIndex(where: { $0.uid == currentItem.uid }) == thresholdIndex {
            Task {
                await fetchNextPage()
            }
        }
    }

    func sortThreadsIntoSections(threads: [Thread]) {
        var newSections = [DateSection]()

        var currentSection: DateSection?
        for thread in threads {
            if currentSection?.threadBelongsToSection(thread: thread) != true {
                currentSection = DateSection(thread: thread)
                newSections.append(currentSection!)
            }
            currentSection?.threads.append(thread)
        }

        sections = newSections
    }

    func editDraft(from thread: Thread) {
        guard let message = thread.messages.first else { return }
        var sheetPresented = false

        // If we already have the draft locally, present it directly
        if let draft = mailboxManager.draft(messageUid: message.uid)?.detached() {
            menuSheet?.state = .editMessage(draft: draft)
            sheetPresented = true
        }

        // Update the draft
        Task { [sheetPresented] in
            let draft = try await mailboxManager.draft(from: message)
            if !sheetPresented {
                menuSheet?.state = .editMessage(draft: draft)
            }
        }
    }


    // MARK: - Swipe actions

    func hanldeSwipeAction(_ action: SwipeAction, thread: Thread) async throws {
        switch action {
        case .delete:
            try await mailboxManager.moveOrDelete(thread: thread)
        case .archive:
            try await move(thread: thread, to: .archive)
        case .readUnread:
            try await mailboxManager.toggleRead(thread: thread)
        case .move:
            globalBottomSheet?.open(state: .move(moveHandler: { folder in
                Task {
                    try await self.move(thread: thread, to: folder)
                }
            }), position: .moveHeight)
        case .favorite:
            try await mailboxManager.toggleStar(thread: thread)
        case .report:
            // TODO: Report action
            showWorkInProgressSnackBar()
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
        IKSnackBar.showCancelableSnackBar(message: MailResourcesStrings.Localizable.snackbarThreadMoved(folderRole.localizedName),
                                          cancelSuccessMessage: MailResourcesStrings.Localizable.snackbarMoveCancelled,
                                          cancelableResponse: response,
                                          mailboxManager: mailboxManager)
    }

    private func move(thread: Thread, to folderRole: FolderRole) async throws {
        guard let folder = mailboxManager.getFolder(with: folderRole)?.freeze() else { return }
        try await move(thread: thread, to: folder)
    }

    private func move(thread: Thread, to folder: Folder) async throws {
        let response = try await mailboxManager.move(thread: thread, to: folder)
        IKSnackBar.showCancelableSnackBar(message: MailResourcesStrings.Localizable.snackbarThreadMoved(folder.localizedName),
                                          cancelSuccessMessage: MailResourcesStrings.Localizable.snackbarMoveCancelled,
                                          cancelableResponse: response,
                                          mailboxManager: mailboxManager)
    }
}
