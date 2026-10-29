/*
 Infomaniak Mail - iOS App
 Copyright (C) 2025 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import Foundation
import RealmSwift

// MARK: - Templates

public extension MailboxManager {
    func refreshTemplates() async throws {
        let templates = try await apiFetcher.mailTemplate(mailbox: mailbox)

        try? writeTransaction { writableRealm in
            let existingTemplates = Array(writableRealm.objects(MailTemplate.self))

            let templatesToAdd = templates.filter { !existingTemplates.contains($0) }
            let templatesToUpdate = templates.filter { existingTemplates.contains($0) }
            let templatesToDelete = Set(existingTemplates.filter { !templates.contains($0) })

            writableRealm.add(templatesToUpdate, update: .modified)
            writableRealm.delete(templatesToDelete)
            writableRealm.add(templatesToAdd, update: .modified)
        }
    }
}
