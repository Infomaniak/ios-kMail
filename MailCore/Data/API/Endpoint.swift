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

// MARK: - Type definition

enum ApiEnvironment {
    case prod, preprod

    public static let current = ApiEnvironment.prod

    var host: String {
        switch self {
        case .prod:
            return "infomaniak.com"
        case .preprod:
            return "preprod.dev.infomaniak.ch"
        }
    }

    var apiHost: String {
        return "api.\(host)"
    }

    var mailHost: String {
        return "mail.\(host)"
    }
}

public struct Endpoint {
    public static let itemsPerPage = 200

    let path: String
    let queryItems: [URLQueryItem]?
    let apiEnvironment: ApiEnvironment
    let host: String

    public var url: URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = path
        components.queryItems = queryItems

        guard let url = components.url else {
            fatalError("Invalid endpoint URL: \(self)")
        }
        return url
    }

    init(path: String, queryItems: [URLQueryItem]? = nil, apiEnvironment: ApiEnvironment = .current, host: String? = nil) {
        self.path = path
        self.queryItems = queryItems
        self.apiEnvironment = apiEnvironment
        if let host = host {
            self.host = host
        } else {
            self.host = apiEnvironment.mailHost
        }
    }

    func appending(path: String, queryItems: [URLQueryItem]? = nil) -> Endpoint {
        return Endpoint(path: self.path + path, queryItems: queryItems, apiEnvironment: apiEnvironment)
    }

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
    private static var baseManager: Endpoint {
        return Endpoint(path: "/1/mail_hostings")
    }

    static var mailbox: Endpoint {
        return Endpoint(path: "/api/mailbox", queryItems: nil)
    }
}
