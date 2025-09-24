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

import Foundation
import InfomaniakCore
import InfomaniakDI
import MailResources
import SwiftRegex
import SwiftSoup
import SwiftUI

public enum DeeplinkConstants {
    public static let macSecurityAndPrivacy = URL(string: "x-apple.systempreferences:com.apple.preference.security")!
    public static let macNotifications = URL(string: "x-apple.systempreferences:com.apple.preference.notifications")!
    public static let iosPreferences = URL(string: "App-prefs:")!

    public static func presentsNotificationSettings() {
        @InjectService var platformDetector: PlatformDetectable
        // swiftlint:disable:next private_environment
        @Environment(\.openURL) var openURL

        let settingsURL: URL?
        if platformDetector.isMac {
            settingsURL = DeeplinkConstants.macNotifications
        } else {
            settingsURL = URL(string: UIApplication.openSettingsURLString)
        }

        guard let settingsURL else { return }
        openURL(settingsURL)
    }
}

public enum DesktopWindowIdentifier {
    public static let settingsWindowIdentifier = "settings"
    public static let composeWindowIdentifier = "compose"
    public static let threadWindowIdentifier = "thread"
    public static let mainWindowIdentifier = "main"
}

public struct URLConstants {
    public static let testFlight = URLConstants(urlString: "https://testflight.apple.com/join/t8dXx60N")
    public static let appStore = URLConstants(urlString: "https://apps.apple.com/app/infomaniak-mail/id1622596573")
    public static let kdriveAppStore = URLConstants(urlString: "https://itunes.apple.com/app/id1482778676")
    public static let importMails = URLConstants(urlString: "https://import-email.infomaniak.com")
    public static let matomo = URLConstants(urlString: "https://analytics.infomaniak.com/matomo.php")
    public static let githubRepository = URLConstants(urlString: "https://github.com/Infomaniak/ios-kMail")
    public static let chatbot = URLConstants(urlString: "https://www.infomaniak.com/chatbot")
    public static let ikMe = URLConstants(urlString: "https://www.ik.me")
    public static let encryptionFAQ = URLConstants(urlString: "https://faq.infomaniak.com/1582")

    public static func calendarEvent(_ event: CalendarEvent) -> URLConstants {
        let startDate = Calendar.current.firstDayOfTheWeek(of: event.start) ?? .now
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.string(from: startDate)

        return URLConstants(urlString: "https://calendar.infomaniak.com/?event=\(event.id)&view=week&from=\(date)")
    }

    private var urlString: String

    public var url: URL {
        guard let url = URL(string: urlString) else {
            fatalError("Invalid URL")
        }
        return url
    }

    public static func getStoreURL() -> URLConstants {
        Bundle.main.isRunningInTestFlight ? testFlight : appStore
    }
}

public enum Constants {
    public static let maxAttachmentsSize = 26_214_400 // 25 mo
    public static let minimumQuotasProgressionToDisplay = 0.03

    public static let threadCellMaxRecipients = 5

    public static let maxFolderNameLength = 255

    public static let matomoId = "9"

    public static let longTimeout: TimeInterval = 120

    // It's safe to unwrap because this will always succeed
    // swiftlint:disable:next force_try
    public static let referenceRegex: NSRegularExpression = try! NSRegularExpression(pattern: ">\\s*<|>?\\s+<?")

    public static let sizeChangeThreshold = 3
    public static let viewportContent = "width=device-width, initial-scale=1.0"
    public static let divWrapperId = "kmail-message-content"
    public static let mungeEmailScript: String? = {
        guard let mungeScript = MailResourcesResources.bundle.load(filename: "mungeEmail", withExtension: "js")
        else { return nil }
        return "const MESSAGE_SELECTOR = \"#\(divWrapperId)\"; \(mungeScript)"
    }()

    public static let breakStringsAtLength = 30

    /// List of feature flags enabled by default (before getting API data)
    public static let defaultFeatureFlags: [FeatureFlag] = []

    public static func isMailTo(_ url: URL) -> Bool {
        return url.scheme?.caseInsensitiveCompare("mailto") == .orderedSame
    }

    public static let signatureHTMLClass = "editorUserSignature"
    public static let forwardQuoteHTMLClass = "forwardContentMessage"
    public static let replyQuoteHTMLClass = "ik_mail_quote"

    public static let forwardRoot = "<div class=\"\(forwardQuoteHTMLClass)\">"
    public static let replyRoot = "<div class=\"\(replyQuoteHTMLClass)\">"

    public static let editorFirstLines = "<div><br></div><div><br></div>"

    public static func globallyResignFirstResponder() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    public static func dateSince() -> String {
        var dateComponents = DateComponents()
        dateComponents.month = -3

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"

        guard let date = Calendar.current.date(byAdding: dateComponents, to: Date())
        else { return dateFormatter.string(from: Date()) }

        return dateFormatter.string(from: date)
    }

    public static func localizedDate(_ date: Date) -> String {
        return DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .short)
    }

    public static let messageQuantityLimit = 500
    public static let numberOfOldUidsToFetch = 10000
    public static let maxChangesCount = 10000
    public static let oldPageSize = 50
    public static let newPageSize = 200
    public static let contactSuggestionLimit = 5

    public static let apiLimit = 1000

    public static let numberOfSecondsInADay: TimeInterval = 86400

    public static let shortDateFormatter = Date.FormatStyle.dateTime.month(.wide)
    public static let longDateFormatter = shortDateFormatter.year()

    public static func shortUid(from longUid: String) -> String {
        return longUid.components(separatedBy: "@")[0]
    }

    public static let appVersionLabel = CorePlatform.appVersionLabel(fallbackAppName: "Mail")

    public static let searchFolderId = "search_folder_id"

    public static let backgroundRefreshTaskIdentifier = "com.infomaniak.mail.background-refresh"

    public static let aiDetectPartsRegex = "^[^:]+:(?<subject>.+?)\n\\s*(?<content>.+)"

    public static let aiPromptExamples: Set = [
        MailResourcesStrings.Localizable.aiPromptExample1,
        MailResourcesStrings.Localizable.aiPromptExample2,
        MailResourcesStrings.Localizable.aiPromptExample3,
        MailResourcesStrings.Localizable.aiPromptExample4,
        MailResourcesStrings.Localizable.aiPromptExample5
    ]

    public static let minimumOpeningBeforeSync = 2
    public static let nextOpeningBeforeSync = 50

    /// A count limit for the Contact cache in Extension mode, where we have strong memory constraints.
    public static let contactCacheExtensionMaxCount = 50

    /// Batch size of inline attachments during processing.
    public static let inlineAttachmentBatchSize = 10

    /// Max parallelism that works well with network requests.
    public static let concurrentNetworkCalls = 4

    public static let appGroupIdentifier = "group.com.infomaniak"

    /// Decodes the date according to the string format, yyyy-MM-dd or ISO 8601
    public static func decodeDateCorrectly(_ date: String) -> Date? {
        if let regex = Regex(pattern: "^[0-9]{4}-[0-9]{2}-[0-9]{2}$"), !regex.matches(in: date).isEmpty {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            return dateFormatter.date(from: date)
        } else {
            let dateFormatter = ISO8601DateFormatter()
            return dateFormatter.date(from: date)
        }
    }

    public static var isUsingABreakableOSVersion: Bool {
        @InjectService var platformDetector: PlatformDetectable

        guard !platformDetector.isMac else { return false }

        let currentVersion = ProcessInfo().operatingSystemVersion
        let isiOS15Breakable = currentVersion.majorVersion == 15 && currentVersion.minorVersion < 7
        let isiOS16Breakable = currentVersion.majorVersion == 16 && currentVersion.minorVersion < 5
        return isiOS15Breakable || isiOS16Breakable
    }
}
