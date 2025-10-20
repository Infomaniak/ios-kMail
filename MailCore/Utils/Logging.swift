/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

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

import Atlantis
import Foundation
import InfomaniakCore
import InfomaniakDI
import InfomaniakLogin
import OSLog
import RealmSwift
import Sentry

public extension PlatformDetectable {
    var isRunningUITests: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.arguments.contains("UI-Testing")
        #else
        return false
        #endif
    }
}

public enum Logging {
    private static var sentryEnvironment: String = Bundle.main.isRunningInTestFlight ? "testflight" : "production"

    public static func initLogging() {
        initSentry()
        initAtlantis()
    }

    /// Add a sentry for an error related to opening a realm
    /// - Parameters:
    ///   - error: The specific error we are dealing with
    ///   - realmConfiguration: The configuration of the current Realm
    public static func reportRealmOpeningError(_ error: Error, realmConfiguration: Realm.Configuration, afterRetry: Bool) {
        let realmInConflict = realmConfiguration.fileURL?.lastPathComponent ?? ""
        Logger.general.error("Unable to load Realm files \(realmInConflict) after a retry:\(afterRetry)")

        SentrySDK.capture(error: error) { scope in
            scope.setContext(value: [
                "File URL": realmInConflict,
                "after a retry": afterRetry
            ], key: "Realm")
        }
    }

    private static func initSentry() {
        SentrySDK.start { options in
            options.tracePropagationTargets = []
            options.dsn = "https://b7e4f5e8fd464659a8e83ead7015e070@sentry-mobile.infomaniak.com/5"
            options.enableUIViewControllerTracing = false
            options.enableUserInteractionTracing = false
            options.enableNetworkTracking = false
            options.enableNetworkBreadcrumbs = false
            options.enableSwizzling = false // We can disable swizzling because we only used it for networking
            options.enableMetricKit = true

            options.beforeSend = { event in
                event.environment = sentryEnvironment
                // if the application is in debug or test mode discard the events
                #if DEBUG
                return nil
                #else
                if UserDefaults.shared.isSentryAuthorized {
                    return event
                } else {
                    return nil
                }
                #endif
            }
        }
    }

    private static func initAtlantis() {
        #if DEBUG
        guard let hostname = ProcessInfo.processInfo.environment["hostname"],
              !hostname.isEmpty
        else {
            return
        }
        Atlantis.start(hostName: hostname)
        #endif
    }

    public static func resetAppForUITestsIfNeeded() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("resetData") {
            UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
            UserDefaults.shared.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)

            for identifier in AppIdentifierBuilder.knownAppKeychainIdentifiers {
                KeychainHelper(accessGroup: identifier).deleteAllTokens()
            }

            @InjectService var appGroupPathProvider: AppGroupPathProvidable
            do {
                let appGroupFileURLs = try FileManager.default.contentsOfDirectory(at: appGroupPathProvider.groupDirectoryURL,
                                                                                   includingPropertiesForKeys: nil,
                                                                                   options: .skipsHiddenFiles)
                for fileURL in appGroupFileURLs {
                    try FileManager.default.removeItem(at: fileURL)
                }

                let documentFileURLs = try FileManager.default.contentsOfDirectory(
                    at: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!,
                    includingPropertiesForKeys: nil,
                    options: .skipsHiddenFiles
                )
                for fileURL in documentFileURLs {
                    try FileManager.default.removeItem(at: fileURL)
                }
            } catch {
                Logger.general.error("resetAppForUITestsIfNeeded \(error)")
            }
        }
        #endif
    }
}

/// Something to centralize log methods per feature
public enum Log {
    public static func tokenAuthentication(_ message: @autoclosure () -> String,
                                           oldToken: ApiToken?,
                                           newToken: ApiToken?,
                                           level: SentryLevel = .debug,
                                           file: StaticString = #file,
                                           function: StaticString = #function,
                                           line: UInt = #line) {
        let message = message()
        let oldTokenMetadata: Any = oldToken?.metadata ?? "NULL"
        let newTokenMetadata: Any = newToken?.metadata ?? "NULL"
        var metadata = [String: Any]()
        metadata["oldToken"] = oldTokenMetadata
        metadata["newToken"] = newTokenMetadata

        SentryDebug.asyncCapture(
            message: message,
            context: metadata,
            level: level,
            extras: ["file": "\(file)", "function": "\(function)", "line": "\(line)"]
        )

        SentryDebug.addAsyncBreadcrumb(level: level,
                                       category: SentryDebug.Category.threadAlgorithm.rawValue,
                                       message: message,
                                       data: metadata)

        if level == .error {
            Logger.general.error("\(message)")
            Logger.general.error("old token: \(String(describing: oldTokenMetadata))")
            Logger.general.error("new token: \(String(describing: newTokenMetadata))")
        } else {
            Logger.general.error("\(message)")
        }
    }
}
