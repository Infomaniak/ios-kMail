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

@MainActor class ThreadListViewModel {
    var mailboxManager: MailboxManager
    var folder: Folder
    var filter = Filter.all {
        didSet {
            Task {
                await fetchThreads()
            }
        }
    }

    var threads: AnyRealmCollection<Thread>
    var observationThreadToken: NotificationToken?

    typealias ListUpdatedCallback = ([Int], [Int], [Int], Bool) -> Void
    var onListUpdated: ListUpdatedCallback?

    init(mailboxManager: MailboxManager, folder: Folder) {
        self.mailboxManager = mailboxManager
        self.folder = folder
        if let cachedFolder = mailboxManager.getRealm().object(ofType: Folder.self, forPrimaryKey: folder.id) {
            threads = AnyRealmCollection(cachedFolder.threads.sorted(by: \.date, ascending: false))
            observationThreadToken = threads.observe(on: .main) { [weak self] changes in
                guard let self = self else { return }
                switch changes {
                case let .initial(results):
                    self.threads = results
                    self.onListUpdated?([], [], [], true)
                case let .update(results, deletions, insertions, modifications):
                    self.threads = results
                    self.onListUpdated?(deletions, insertions, modifications, false)
                case .error:
                    break
                }
            }
        } else {
            threads = AnyRealmCollection(mailboxManager.getRealm().objects(Thread.self)
                .filter(NSPredicate(format: "FALSEPREDICATE")))
        }
    }

    func fetchThreads() async {
        do {
            try await mailboxManager.threads(folder: folder.freeze(), filter: filter)
        } catch {
            print("Error while getting threads: \(error)")
        }
    }
}
