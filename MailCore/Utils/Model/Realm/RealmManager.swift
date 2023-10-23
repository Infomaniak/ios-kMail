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

import CocoaLumberjackSwift
import Foundation
import InfomaniakDI
import RealmSwift

protocol RealmManageable {
    func handleRealmOpeningError(_ error: Error, realmConfiguration: Realm.Configuration)
}

struct RealmManager: RealmManageable {
    @LazyInjectService private var platformDetector: PlatformDetectable

    func handleRealmOpeningError(_ error: Error, realmConfiguration: Realm.Configuration) {
        // We report this error on Sentry
        Logging.reportRealmOpeningError(error, realmConfiguration: realmConfiguration)

        // If app is running on macOS (no clean on uninstall) or debug, clean DB
        if platformDetector.isMacCatalyst || platformDetector.isiOSAppOnMac || platformDetector.isDebug {
            DDLogError(
                "Realm files \(realmConfiguration.fileURL?.lastPathComponent ?? "") will be deleted to prevent migration error for next launch"
            )
            _ = try? Realm.deleteFiles(for: realmConfiguration)
        }

        // Currently on iOS we terminate early if unable to migrate
        else {
            fatalError("Failed creating realm \(error.localizedDescription)")
        }
    }
}
