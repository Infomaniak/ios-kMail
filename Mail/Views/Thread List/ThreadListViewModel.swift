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

typealias Thread = MailCore.Thread

@MainActor class ThreadListViewModel {
    var mailboxManager: MailboxManager
    var folder: Folder?
    var filter = Filter.all {
        didSet {
            Task {
                await fetchThreads()
            }
        }
    }

    var threads = [Thread]()

    init(mailboxManager: MailboxManager, folder: Folder?) {
        self.mailboxManager = mailboxManager
        self.folder = folder
    }

    func fetchThreads() async {
        do {
            guard let folder = folder else { return }
            threads = try await mailboxManager.threads(folder: folder, filter: filter)
        } catch {
            print("Error while getting threads: \(error)")
        }
    }
}
