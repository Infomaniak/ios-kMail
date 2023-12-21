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

import Atlantis
import CocoaLumberjack
import CocoaLumberjackSwift
import Foundation
import InfomaniakCore
import RealmSwift
import Sentry

public enum Logging {
    public static func initLogging() {
        initLogger()
        initSentry()
        initAtlantis()
    }

    class LogFormatter: NSObject, DDLogFormatter {
        func format(message logMessage: DDLogMessage) -> String? {
            return "[Infomaniak] \(logMessage.message)"
        }
    }

    /// Add a sentry for an error related to opening a realm
    /// - Parameters:
    ///   - error: The specific error we are dealing with
    ///   - realmConfiguration: The configuration of the current Realm
    public static func reportRealmOpeningError(_ error: Error, realmConfiguration: Realm.Configuration, afterRetry: Bool) {
        let realmInConflict = realmConfiguration.fileURL?.lastPathComponent ?? ""
        DDLogError("Unable to load Realm files \(realmInConflict) after a retry:\(afterRetry)")

        SentrySDK.capture(error: error) { scope in
            scope.setContext(value: [
                "File URL": realmInConflict,
                "after a retry": afterRetry
            ], key: "Realm")
        }
    }

    private static func initLogger() {
        DDOSLogger.sharedInstance.logFormatter = LogFormatter()
        DDLog.add(DDOSLogger.sharedInstance, with: .info)
        let logFileManager = DDLogFileManagerDefault(logsDirectory: MailboxManager.constants.cacheDirectoryURL
            .appendingPathComponent("logs", isDirectory: true).path)
        let fileLogger = DDFileLogger(logFileManager: logFileManager)
        fileLogger.rollingFrequency = 60 * 60 * 24 // 24 hours
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7
        DDLog.add(fileLogger)
    }

    private static func initSentry() {
        SentrySDK.start { options in
            options.environment = Bundle.main.isRunningInTestFlight ? "testflight" : "production"
            options.tracePropagationTargets = []
            options.dsn = "https://b7e4f5e8fd464659a8e83ead7015e070@sentry-mobile.infomaniak.com/5"
            options.beforeSend = { event in
                // if the application is in debug or test mode discard the events
                #if DEBUG || TEST
                return nil
                #else
                return event
                #endif
            }
        }
    }

    private static func initAtlantis() {
        #if DEBUG && !TEST
        guard let hostname = ProcessInfo.processInfo.environment["hostname"],
              !hostname.isEmpty else {
            return
        }
        Atlantis.start(hostName: hostname)
        #endif
    }
}
