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

import Combine
import Foundation
import InfomaniakCore
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
                return .init(start: .now.startOfDay, duration: Constants.numberOfSecondsInADay)
            case .yesterday:
                return .init(start: .yesterday.startOfDay, duration: Constants.numberOfSecondsInADay)
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

final class DateSection: Identifiable, Equatable {
    static func == (lhs: DateSection, rhs: DateSection) -> Bool {
        lhs.id == rhs.id && lhs.title == rhs.title && lhs.threads == rhs.threads
    }

    let id: String
    let title: String
    let threads: [Thread]

    init(sectionKey: String, threads: [Thread]) {
        id = sectionKey
        title = Thread.ReferenceDate.titleFromRawSectionKey(sectionKey)
        self.threads = threads
    }
}

@MainActor final class ThreadListViewModel: ObservableObject {
    let mailboxManager: MailboxManager

    let folder: Folder

    @Published var sections: [DateSection]?
    let sectionsSubject = PassthroughSubject<[DateSection]?, Never>()
    var sectionsObserver: AnyCancellable?

    @Published var loadingPageTaskId: UUID?

    var selectedThreadOwner: SelectedThreadOwnable
    var filteredThreads = [Thread]()

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

    @Published var filter = Filter.all {
        didSet {
            Task {
                SentryDebug.filterChangedBreadcrumb(filterValue: filter.rawValue)
                if filter == .unseen {
                    observeFilteredResults()
                } else {
                    stopObserveFilteredThreads()
                }

                observeChanges()

                guard let topThread = sections?.first?.threads.first?.id else {
                    return
                }
                withAnimation {
                    self.scrollViewProxy?.scrollTo(topThread, anchor: .top)
                }
            }
        }
    }

    var isEmpty: Bool {
        return sections?.isEmpty == true
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
        selectedThreadOwner: SelectedThreadOwnable,
        isCompact: Bool
    ) {
        assert(folder.isFrozen, "ThreadListViewModel.folder should always be frozen")
        self.mailboxManager = mailboxManager
        self.folder = folder
        self.selectedThreadOwner = selectedThreadOwner
        self.isCompact = isCompact
        sectionsObserver = sectionsSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newSections in
                withAnimation {
                    self?.sections = newSections
                }
            }
        observeChanges()
        observeUnreadCount()
    }

    func fetchThreads() async {
        guard loadingPageTaskId == nil else {
            return
        }

        withAnimation {
            loadingPageTaskId = UUID()
        }

        await mailboxManager.refreshFolderContent(folder)

        withAnimation {
            loadingPageTaskId = nil
        }
    }

    func nextThreadIfNeeded(oldThreads: [Thread], newThreads: [Thread]) {
        // No more threads ?
        guard !newThreads.isEmpty else {
            selectedThreadOwner.selectedThread = nil
            return
        }

        // Only move if selected thread is not present in the new list
        guard let oldSelectedThread = selectedThreadOwner.selectedThread,
              !newThreads.contains(where: { $0.uid == oldSelectedThread.uid }),
              let oldSelectedThreadIndex = oldThreads.firstIndex(where: { $0.uid == oldSelectedThread.uid }) else {
            return
        }

        if isCompact {
            selectedThreadOwner.selectedThread = nil
        } else {
            let validIndex = min(oldSelectedThreadIndex, newThreads.count - 1)
            selectedThreadOwner.selectedThread = newThreads[validIndex]
        }
    }

    func nextThread() {
        guard !filteredThreads.isEmpty,
              let currentThread = selectedThreadOwner.selectedThread,
              let currentThreadIndex = filteredThreads.firstIndex(where: { $0.uid == currentThread.uid }),
              currentThreadIndex < filteredThreads.count - 1 else { return }
        let newIndex = currentThreadIndex + 1
        selectedThreadOwner.selectedThread = filteredThreads[newIndex]
    }

    func previousThread() {
        guard !filteredThreads.isEmpty,
              let currentThread = selectedThreadOwner.selectedThread,
              let currentThreadIndex = filteredThreads.firstIndex(where: { $0.uid == currentThread.uid }),
              currentThreadIndex > 0 else { return }
        let newIndex = currentThreadIndex - 1
        selectedThreadOwner.selectedThread = filteredThreads[newIndex]
    }

    func resetFilterIfNeeded(filteredThreads: [Thread]) {
        if filteredThreads.isEmpty && filterUnreadOn {
            DispatchQueue.main.sync {
                filterUnreadOn.toggle()
            }
        }
    }
}
