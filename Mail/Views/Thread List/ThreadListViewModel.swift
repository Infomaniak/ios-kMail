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
import MailCore
import RealmSwift

typealias Thread = MailCore.Thread

@MainActor class ThreadListViewModel: ObservableObject {
    var mailboxManager: MailboxManager

    @Published var folder: Folder?
    @Published var threads: AnyRealmCollection<Thread>
    @Published var isLoadingPage = false

    private var resourceNext: String?
    private var observationThreadToken: NotificationToken?

    var filter = Filter.all {
        didSet {
            Task {
                await fetchThreads()
            }
        }
    }

    init(mailboxManager: MailboxManager, folder: Folder?) {
        self.mailboxManager = mailboxManager
        self.folder = folder

        let realm = mailboxManager.getRealm()
        if let folder = folder,
           let cachedFolder = realm.object(ofType: Folder.self, forPrimaryKey: folder.id) {
            threads = AnyRealmCollection(cachedFolder.threads.sorted(by: \.date, ascending: false))
            observeChanges()
        } else {
            threads = AnyRealmCollection(realm.objects(Thread.self).filter(NSPredicate(format: "FALSEPREDICATE")))
        }
    }

    func fetchThreads() async {
        guard !isLoadingPage else {
            return
        }

        isLoadingPage = true

        do {
            guard let folder = folder else { return }
            let result = try await mailboxManager.threads(folder: folder.freeze(), filter: filter)
            resourceNext = result.resourceNext
        } catch {
            print("Error while getting threads: \(error)")
        }
        isLoadingPage = false
        mailboxManager.draftOffline()
    }

    func fetchNextPage() async {
        guard !isLoadingPage, let resource = resourceNext else {
            return
        }

        isLoadingPage = true

        do {
            guard let folder = folder else { return }
            let result = try await mailboxManager.threads(folder: folder.freeze(), resource: resource)
            resourceNext = result.resourceNext
        } catch {
            print("Error while getting threads: \(error)")
        }
        isLoadingPage = false
        mailboxManager.draftOffline()
    }

    func updateThreads(with folder: Folder) {
        self.folder = folder
        let realm = mailboxManager.getRealm()
        if let cachedFolder = realm.object(ofType: Folder.self, forPrimaryKey: folder.id) {
            threads = AnyRealmCollection(cachedFolder.threads.sorted(by: \.date, ascending: false))
            observeChanges()
        } else {
            threads = AnyRealmCollection(realm.objects(Thread.self).filter(NSPredicate(format: "FALSEPREDICATE")))
        }

        Task {
            await self.fetchThreads()
        }
    }

    func observeChanges() {
        observationThreadToken?.invalidate()
        observationThreadToken = threads.observe(on: .main) { [weak self] changes in
            guard let self = self else { return }
            switch changes {
            case let .initial(results):
                self.threads = results.freeze()
            case let .update(results, _, _, _):
                self.threads = results.freeze()
            case .error:
                break
            }
        }
    }

    func delete(thread: Thread) async {
        do {
            try await mailboxManager.moveOrDelete(thread: thread)
        } catch {
            print("Error while deleting thread: \(error.localizedDescription)")
        }
    }

    func toggleRead(thread: Thread) async {
        do {
            _ = try await mailboxManager.toggleRead(thread: thread)
        } catch {
            print("Error while marking thread as seen: \(error.localizedDescription)")
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
}
