//
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
import InfomaniakDI
import RealmSwift

/// Something to share the functionality of forcing Realm to migrate
///
/// useful from app extension
public struct ModelMigrator {
    public init() {}

    /// Perform a getRealm on each realm store to trigger a migration if needed
    public func migrateRealmIfNeeded() {
        @InjectService var mailboxInfosManager: MailboxInfosManager
        // .writeTransaction internal call to .getRealm will trigger the migration if needed
        try? mailboxInfosManager.writeTransaction { _ in }

        @InjectService var accountManager: AccountManager
        if let currentMailboxManager = accountManager.currentMailboxManager {
            // Force migration by performing a transaction
            try? currentMailboxManager.writeTransaction { _ in }
        }

        if let contactManager = accountManager.currentContactManager {
            // Force migration by performing a transaction
            _ = try? contactManager.writeTransaction { _ in }
        }
    }
}
