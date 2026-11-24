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

private enum TemplatePaginationError: Error {
    case invalidPageInfo
}

public extension MailboxManager {
    @MainActor
    func refreshTemplates() async throws {
        var templates: [MailTemplate] = []
        var page = 0
        var totalPages = 1

        while page < totalPages {
            try Task.checkCancellation()
            page += 1
            let response = try await apiFetcher.mailTemplate(mailbox: mailbox, page: page)

            guard let currentPage = response.page,
                  let pages = response.pages,
                  currentPage == page,
                  pages >= 0,
                  currentPage <= max(pages, 1),
                  pages != 0 || response.data.isEmpty else {
                throw TemplatePaginationError.invalidPageInfo
            }

            templates.append(contentsOf: response.data)
            totalPages = pages
        }
        try Task.checkCancellation()

        try? writeTransaction { writableRealm in
            writableRealm.delete(writableRealm.objects(MailTemplate.self))
            writableRealm.add(templates, update: .modified)
        }
    }
}
