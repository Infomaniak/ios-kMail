/*
 Infomaniak Mail - iOS App
 Copyright (C) 2023 Infomaniak Network SA

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

import CocoaLumberjackSwift
import Foundation
import InfomaniakDI
import RealmSwift
import Sentry

/// Something to perform shared operation on a given Realm
public protocol RealmManageable {
    /// Delete all given stored data for a given configuration
    func deleteFiles(for config: Realm.Configuration)
}

public struct RealmManager: RealmManageable {
    enum Message {
        static let deleteRealmFiles = "DeleteRealmFiles"
    }

    public init() {}

    public func deleteFiles(for configuration: Realm.Configuration) {
        let realmInConflict = configuration.fileURL?.lastPathComponent ?? ""
        SentrySDK.capture(message: Message.deleteRealmFiles) { scope in
            scope.setContext(value: [
                "File URL": realmInConflict
            ], key: "Realm")
        }

        DDLogError("Realm files \(realmInConflict) will be deleted")

        _ = try? Realm.deleteFiles(for: configuration)
    }
}
