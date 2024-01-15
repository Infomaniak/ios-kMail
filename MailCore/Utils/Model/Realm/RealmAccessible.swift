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
import Realm
import RealmSwift

/// Something that can access a realm with a given configuration
public protocol RealmAccessible {
    /// Configuration for a given realm
    var realmConfiguration: Realm.Configuration { get }

    /// Fetches an up to date realm for a given configuration, or fail in a controlled manner
    func getRealm() -> Realm

    /// Set `isExcludedFromBackup = true`  to the folder where realm is located to exclude a realm cache from an iCloud backup
    /// - Important: Avoid calling this method too often as this can be expensive, prefer calling it once at init time
    func excludeRealmFromBackup()
}

public extension RealmAccessible {
    func getRealm() -> Realm {
        getRealm(canRetry: true)
    }

    /// Try to load a realm for a configuration or retry on supported platforms
    /// - Parameter canRetry: Allow to stop recursion
    /// - Returns: An up to date Realm for a given configuration
    private func getRealm(canRetry: Bool) -> Realm {
        do {
            let realm = try Realm(configuration: realmConfiguration)
            realm.refresh()
            return realm
        } catch let error as RLMError
            where error.code == .fail && (error.userInfo[RLMErrorCodeNameKey] as? String) == "InvalidSchemaVersion" {
            // If scheme version is invalid simply delete the current realm and retry with a new one
            // (we still report the error just in case because it shouldn't happen in production)
            Logging.reportRealmOpeningError(error, realmConfiguration: realmConfiguration, afterRetry: !canRetry)

            @InjectService var realmManager: RealmManageable
            realmManager.deleteFiles(for: realmConfiguration)

            return getRealm(canRetry: false)
        } catch {
            Logging.reportRealmOpeningError(error, realmConfiguration: realmConfiguration, afterRetry: !canRetry)

            guard canRetry else {
                // Unable to recover after cleaning realm a first time
                fatalError("Failed creating realm after a retry \(error.localizedDescription)")
            }

            // Retry without recursion
            return getRealm(canRetry: false)
        }
    }

    func excludeRealmFromBackup() {
        guard var realmFolderURL = realmConfiguration.fileURL?.deletingLastPathComponent() else {
            return
        }

        var metadata = URLResourceValues()
        metadata.isExcludedFromBackup = true
        try? realmFolderURL.setResourceValues(metadata)
    }
}
