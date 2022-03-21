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

@MainActor class MenuDrawerViewModel: ObservableObject {
    @ObservedResults(Folder.self) var folders
    var mailboxManager: MailboxManager

    init(mailboxManager: MailboxManager) {
        self.mailboxManager = mailboxManager
        _folders = .init(Folder.self, configuration: mailboxManager.realmConfiguration, filter: NSPredicate(format: "parentLink.@count == 0"))
    }

    func fetchFolders() async {
        do {
            try await mailboxManager.folders()
        } catch {
            print("Error while getting folders: \(error.localizedDescription)")
        }
    }
}
