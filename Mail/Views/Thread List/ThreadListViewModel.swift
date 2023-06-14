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
import InfomaniakCoreUI
import MailCore
import MailResources
import RealmSwift
import SwiftUI

typealias Thread = MailCore.Thread

final class DateSection: Identifiable, Equatable {
    static func == (lhs: DateSection, rhs: DateSection) -> Bool {
        lhs.id == rhs.id && lhs.title == rhs.title && lhs.threads == rhs.threads
    }

    enum ReferenceDate {
        case future, today, yesterday, thisWeek, lastWeek, thisMonth, older(Date)

        public var dateInterval: DateInterval {
            switch self {
            case .future:
                return DateInterval.future
            case .today:
                return .init(start: .now.startOfDay, duration: Constants.numberOfSecondsInADay)
            case .yesterday:
                return .init(start: .yesterday.startOfDay, duration: Constants.numberOfSecondsInADay)
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
            case .future:
                return MailResourcesStrings.Localizable.comingSoon
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
                let formatStyle = Calendar.current.isDate(date, equalTo: .now, toGranularity: .year)
                    ? Constants.shortDateFormatter
                    : Constants.longDateFormatter
                return date.formatted(formatStyle).capitalized
            }
        }

        func contains(date: Date) -> Bool {
            if case .future = self {
                return date > .now
            }
            return dateInterval.contains(date)
        }
    }

    let id: DateInterval
    let title: String
    var threads = [Thread]()

    private let referenceDate: ReferenceDate

    init(thread: Thread) {
        let sections: [ReferenceDate] = [.future, .today, .yesterday, .thisWeek, .lastWeek, .thisMonth]
        referenceDate = sections.first { $0.contains(date: thread.date) } ?? .older(thread.date)
        id = referenceDate.dateInterval
        title = referenceDate.title
    }

    func threadBelongsToSection(thread: Thread) -> Bool {
        return referenceDate.contains(date: thread.date)
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

    // Used to know thread location
    private var selectedThreadIndex: Int?
    var filteredThreads = [Thread]() {
        didSet {
            guard let thread = selectedThread,
                  let index = filteredThreads.firstIndex(where: { $0.uid == thread.uid }) else { return }
            selectedThreadIndex = index
        }
    }

    var scrollViewProxy: ScrollViewProxy?
    var isCompact: Bool

    /// Observe a filtered thread
    var observeFilteredThreadsToken: NotificationToken?
    /// Observe unread count
    var observationUnreadToken: NotificationToken?
    var observationThreadToken: NotificationToken?
    var observationLastUpdateToken: NotificationToken?
    let observeQueue = DispatchQueue(label: "com.infomaniak.observation.ThreadListViewModel", qos: .userInteractive)

    private let loadNextPageThreshold = 10

    @Published var unreadCount = 0 {
        didSet {
            // Disable filter if we have no unread emails left
            if unreadCount == 0 && filterUnreadOn {
                filterUnreadOn = false
            }
        }
    }

    @Published var filter = Filter.all {
        didSet {
            Task {
                if filter == .unseen {
                    observeFilteredResults()
                } else {
                    stopObserveFilteredThreads()
                }

                observeChanges(animateInitialThreadChanges: true)

                guard let topThread = sections.first?.threads.first?.id else {
                    return
                }
                withAnimation {
                    self.scrollViewProxy?.scrollTo(topThread, anchor: .top)
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

    // MARK: Init

    init(
        mailboxManager: MailboxManager,
        folder: Folder,
        isCompact: Bool
    ) {
        self.mailboxManager = mailboxManager
        self.folder = folder
        lastUpdate = folder.lastUpdate
        self.isCompact = isCompact
        observeChanges()
        observeUnreadCount()
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

    func nextThreadIfNeeded(from threads: [Thread]) {
        guard !isCompact,
              !threads.isEmpty,
              !threads.contains(where: { $0.uid == selectedThread?.uid }),
              let lastIndex = selectedThreadIndex else { return }
        let validIndex = min(lastIndex, threads.count - 1)
        selectedThread = threads[validIndex]
    }

    func sortThreadsIntoSections(threads: [Thread]) -> [DateSection]? {
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
}
