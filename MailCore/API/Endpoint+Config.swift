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
    var configHost: String {
        return "config.\(host)"
    }
}

// MARK: - Endpoints

public extension Endpoint {
    private static var baseConfig: Endpoint {
        return Endpoint(hostKeypath: \.configHost, path: "/api")
    }

    static func downloadSyncProfile(syncContacts: Bool, syncCalendar: Bool) -> Endpoint {
        return .baseConfig.appending(path: "/sync/dav/download",
                                     queryItems: [URLQueryItem(name: "carddav", value: "\(syncContacts ? 1 : 0)"),
                                                  URLQueryItem(name: "caldav", value: "\(syncCalendar ? 1 : 0)")])
    }

    static var applicationPassword: Endpoint {
        return .baseConfig.appending(path: "/securedProxy/profile/password")
    }
}
