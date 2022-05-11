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

// MARK: - Type definition

public extension ApiEnvironment {
    var mailHost: String {
        return "mail.\(host)"
    }
}

public extension Endpoint {
    static let itemsPerPage = 200

    func paginated(page: Int = 1) -> Endpoint {
        let paginationQueryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per_page", value: "\(Endpoint.itemsPerPage)")
        ]

        return Endpoint(path: path, queryItems: (queryItems ?? []) + paginationQueryItems, apiEnvironment: apiEnvironment)
    }
}

// MARK: - Endpoints

public extension Endpoint {
    static func resource(_ resource: String, queryItems: [URLQueryItem]? = nil) -> Endpoint {
        return Endpoint(hostKeypath: \.mailHost, path: resource, queryItems: queryItems)
    }

    private static var baseManager: Endpoint {
        return Endpoint(path: "/1/mail_hostings")
    }

    private static var base: Endpoint {
        return Endpoint(hostKeypath: \.mailHost, path: "/api")
    }

    static var mailboxes: Endpoint {
        return .base.appending(path: "/mailbox")
    }

    private static func mailbox(uuid: String) -> Endpoint {
        return .base.appending(path: "/mail/\(uuid)")
    }

    static func signatures(hostingId: Int, mailboxName: String) -> Endpoint {
        return .baseManager.appending(path: "/\(hostingId)/mailboxes/\(mailboxName)/signatures")
    }

    static func folders(uuid: String) -> Endpoint {
        return .mailbox(uuid: uuid).appending(path: "/folder")
    }

    static func threads(uuid: String, folderId: String, filter: String?) -> Endpoint {
        return .folders(uuid: uuid).appending(path: "/\(folderId)/message", queryItems: [
            URLQueryItem(name: "offset", value: "0"),
            URLQueryItem(name: "thread", value: "on"),
            URLQueryItem(name: "filters", value: filter)
        ])
    }

    static func quotas(mailbox: String, productId: Int) -> Endpoint {
        return .mailboxes.appending(path: "/quotas", queryItems: [
            URLQueryItem(name: "mailbox", value: mailbox),
            URLQueryItem(name: "product_id", value: "\(productId)")
        ])
    }

    static func draft(uuid: String) -> Endpoint {
        return .mailbox(uuid: uuid).appending(path: "/draft")
    }

    static func draft(uuid: String, draftUuid: String) -> Endpoint {
        return .draft(uuid: uuid).appending(path: "/\(draftUuid)")
    }
}
