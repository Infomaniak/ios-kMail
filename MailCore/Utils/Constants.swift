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
import MailResources
import SwiftRegex
import SwiftSoup
import SwiftUI

public enum DeeplinkConstants {
    public static let macSecurityAndPrivacy = URL(string: "x-apple.systempreferences:com.apple.preference.security")!
    public static let iosPreferences = URL(string: "App-prefs:")!
}

public enum DesktopWindowIdentifier {
    public static let settingsWindowIdentifier = "settings"
    public static let composeWindowIdentifier = "compose"
}

public struct URLConstants {
    public static let testFlight = URLConstants(urlString: "https://testflight.apple.com/join/t8dXx60N")
    public static let appStore = URLConstants(urlString: "https://apps.apple.com/app/infomaniak-mail/id1622596573")
    public static let kdriveAppStore = URLConstants(urlString: "https://itunes.apple.com/app/id1482778676")
    public static let importMails = URLConstants(urlString: "https://import-email.infomaniak.com")
    public static let matomo = URLConstants(urlString: "https://analytics.infomaniak.com/matomo.php")
    public static let faq =
        URLConstants(
            urlString: "https://www.infomaniak.com/\(Locale.current.languageCode ?? "fr")/support/faq/admin2/service-mail"
        )
    public static let chatbot = URLConstants(urlString: "https://www.infomaniak.com/chatbot")
    public static let ikMe = URLConstants(urlString: "https://www.ik.me")

    public static func calendarEvent(_ event: CalendarEvent) -> URLConstants {
        let startDate = Calendar.current.firstDayOfTheWeek(of: event.start) ?? .now
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.string(from: startDate)

        return URLConstants(urlString: "https://calendar.infomaniak.com/?event=\(event.id)&view=week&from=\(date)")
    }

    public static let schemeUrl = "http"

    private var urlString: String

    public var url: URL {
        guard let url = URL(string: urlString) else {
            fatalError("Invalid URL")
        }
        return url
    }
}

public enum Constants {
    public static let maxAttachmentsSize = 26_214_400 // 25 mo
    public static let sizeLimit = 21_474_836_480 // 20 Go
    public static let minimumQuotasProgressionToDisplay = 0.03

    public static let threadCellMaxRecipients = 5

    public static let maxFolderNameLength = 255

    public static let matomoId = "9"

    public static let longTimeout: TimeInterval = 120

    public static let emailPredicate = NSPredicate(format: "SELF MATCHES %@", Constants.mailRegex)
    public static let mailRegex =
        "(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])"
    public static var referenceRegex: NSRegularExpression = // It's safe to unwrap because this will always succeed
        // swiftlint:disable:next force_try
        try! NSRegularExpression(pattern: ">\\s*<|>?\\s+<?")

    public static let sizeChangeThreshold = 3
    public static let viewportContent = "width=device-width, initial-scale=1.0"
    public static let divWrapperId = "kmail-message-content"
    public static let mungeEmailScript: String? = {
        guard let mungeScript = Bundle.main.load(filename: "mungeEmail", withExtension: "js") else { return nil }
        return "const MESSAGE_SELECTOR = \"#\(divWrapperId)\"; \(mungeScript)"
    }()

    public static let breakStringsAtLength = 30

    /// List of feature flags enabled by default (before getting API data)
    public static let defaultFeatureFlags: [FeatureFlag] = []

    public static func isEmailAddress(_ mail: String) -> Bool {
        return emailPredicate.evaluate(with: mail.lowercased())
    }

    public static func isMailTo(_ url: URL) -> Bool {
        return url.scheme?.caseInsensitiveCompare("mailto") == .orderedSame
    }

    public static let signatureHTMLClass = "editorUserSignature"
    public static let forwardQuoteHTMLClass = "forwardContentMessage"
    public static let replyQuoteHTMLClass = "ik_mail_quote"

    public static let forwardRoot = "<div class=\"\(forwardQuoteHTMLClass)\">"
    public static let replyRoot = "<div class=\"\(replyQuoteHTMLClass)\">"

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
    public static let pageSize = 50
    public static let contactSuggestionLimit = 5

    public static let numberOfSecondsInADay: TimeInterval = 86400

    public static let shortDateFormatter = Date.FormatStyle.dateTime.month(.wide)
    public static let longDateFormatter = shortDateFormatter.year()

    public static func longUid(from shortUid: String, folderId: String) -> String {
        return "\(shortUid)@\(folderId)"
    }

    public static func shortUid(from longUid: String) -> String {
        return longUid.components(separatedBy: "@")[0]
    }

    public static func appVersion() -> String {
        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as! String? ?? "Mail"
        let release = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String? ?? "x.x"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String? ?? "x"
        let betaRelease = Bundle.main.isRunningInTestFlight ? "beta" : ""

        return "\(appName) iOS version \(release)-\(betaRelease)\(build)"
    }

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

    public static let openingBeforeReview = 50
    public static let minimumOpeningBeforeSync = 2

    /// A count limit for the Contact cache in Extension mode, where we have strong memory constraints.
    public static let contactCacheExtensionMaxCount = 50

    /// Batch size of inline attachments during processing.
    public static let inlineAttachmentBatchSize = 10

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
}
