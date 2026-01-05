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

import Foundation
import InfomaniakCoreDB
import InfomaniakDI
import OSLog
import Realm
import RealmSwift

/// Centralised way to access a realm configuration and instance.
///
/// MailCoreRealmAccessible is only intended to be used by `BackgroundRealm`
protocol MailCoreRealmAccessible: RealmAccessible, RealmConfigurable {}

/// Default shared getRealm() implementation with migration retry
extension MailCoreRealmAccessible {
    public func getRealm() -> Realm {
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
        } catch let error as RLMError where error.code == .fail || error.code == .schemaMismatch {
            // If scheme version is invalid simply delete the current realm and retry with a new one
            // (we still report the error just in case because it shouldn't happen in production)
            Logging.reportRealmOpeningError(error, realmConfiguration: realmConfiguration, afterRetry: !canRetry)

            @InjectService var realmManager: RealmManageable
            realmManager.deleteFiles(for: realmConfiguration)

            #if DEBUG
            Logger.general.error("Realm files will be deleted, you can resume the app with the debugger")
            raise(SIGINT)
            #endif
            
            guard canRetry else {
                fatalError("Failed creating realm after a retry \(error.localizedDescription)")
            }

            return getRealm(canRetry: false)
        } catch {
            Logging.reportRealmOpeningError(error, realmConfiguration: realmConfiguration, afterRetry: !canRetry)

            guard canRetry else {
                fatalError("Failed creating realm after a retry \(error.localizedDescription)")
            }

            return getRealm(canRetry: false)
        }
    }
}

/// Default implementation handling iCloud backup exclusion
public extension RealmConfigurable {
    func excludeRealmFromBackup() {
        guard var realmFolderURL = realmConfiguration.fileURL?.deletingLastPathComponent() else {
            return
        }

        var metadata = URLResourceValues()
        metadata.isExcludedFromBackup = true
        try? realmFolderURL.setResourceValues(metadata)
    }
}

/// Some type conforming to MailCoreRealmAccessible
struct MailCoreRealmAccessor: MailCoreRealmAccessible {
    var realmConfiguration: Realm.Configuration
}
