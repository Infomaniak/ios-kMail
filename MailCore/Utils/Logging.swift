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
import InfomaniakLogin
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

    public static func reportRealmOpeningError(_ error: Error, realmConfiguration: Realm.Configuration) -> Never {
        SentrySDK.capture(error: error) { scope in
            scope.setContext(value: [
                "File URL": realmConfiguration.fileURL?.absoluteString ?? ""
            ], key: "Realm")
        }
        #if DEBUG
            DDLogError(
                "Realm files \(realmConfiguration.fileURL?.lastPathComponent ?? "") will be deleted to prevent migration error for next launch"
            )
            _ = try? Realm.deleteFiles(for: realmConfiguration)
        #endif
        fatalError("Failed creating realm \(error.localizedDescription)")
    }

    private static func initLogger() {
        DDOSLogger.sharedInstance.logFormatter = LogFormatter()
        DDLog.add(DDOSLogger.sharedInstance)
        let logFileManager = DDLogFileManagerDefault(logsDirectory: MailboxManager.constants.cacheDirectoryURL
            .appendingPathComponent("logs", isDirectory: true).path)
        let fileLogger = DDFileLogger(logFileManager: logFileManager)
        fileLogger.rollingFrequency = 60 * 60 * 24 // 24 hours
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7
        DDLog.add(fileLogger)
    }

    private static func initSentry() {
        SentrySDK.start { options in
            options.dsn = "https://a9e3e85be0c246fb9ab0e19be1785c89@sentry.infomaniak.com/42"
            options.beforeSend = { event in
                // if the application is in debug mode discard the events
                #if DEBUG
                    return nil
                #else
                    return event
                #endif
            }
        }
    }

    private static func initAtlantis() {
        #if DEBUG
            Atlantis.start(hostName: ProcessInfo.processInfo.environment["hostname"])
        #endif
    }
}

// MARK: - Token Logging

extension ApiToken {
    var truncatedAccessToken: String {
        truncateToken(accessToken)
    }

    var truncatedRefreshToken: String {
        truncateToken(refreshToken)
    }

    private func truncateToken(_ token: String) -> String {
        String(token.prefix(4) + "-*****-" + token.suffix(4))
    }

    func generateBreadcrumb(level: SentryLevel, message: String, keychainError: OSStatus = noErr) -> Breadcrumb {
        let crumb = Breadcrumb(level: level, category: "Token")
        crumb.type = level == .info ? "info" : "error"
        crumb.message = message
        crumb.data = ["User id": userId,
                      "Expiration date": expirationDate.timeIntervalSince1970,
                      "Access Token": truncatedAccessToken,
                      "Refresh Token": truncatedRefreshToken,
                      "Keychain error code": keychainError]
        return crumb
    }
}
