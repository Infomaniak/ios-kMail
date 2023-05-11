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
import SwiftSoup
import SwiftUI

public struct URLConstants {
    public static let importMails = URLConstants(urlString: "https://import-email.infomaniak.com")
    public static let matomo = URLConstants(urlString: "https://analytics.infomaniak.com/matomo.php")
    public static let faq =
        URLConstants(
            urlString: "https://www.infomaniak.com/\(Locale.current.languageCode ?? "fr")/support/faq/admin2/service-mail"
        )
    public static let chatbot = URLConstants(urlString: "https://www.infomaniak.com/chatbot")
    public static let ikMe = URLConstants(urlString: "https://www.ik.me")

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

    public static let dismissMoveSheetNotificationName = Notification.Name(rawValue: "SheetViewDismiss")

    public static let maxFolderNameLength = 255

    public static let matomoId = "9"

    public static let emailPredicate = NSPredicate(format: "SELF MATCHES %@", Constants.mailRegex)
    public static let mailRegex =
        "(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])"
    public static var referenceRegex: NSRegularExpression = {
        // It's safe to unwrap because this will always succeed
        // swiftlint:disable force_try
        try! NSRegularExpression(pattern: ">\\s*<|>?\\s+<?")
    }()

    public static let viewportContent = "width=device-width, initial-scale=1.0"
    public static let divWrapperId = "kmail-message-content"
    public static let styleCSS = {
        guard let style = Bundle.main.loadCSS(filename: "style") else { return "" }

        let variables = """
        :root {
            --kmail-primary-color: \(UserDefaults.shared.accentColor.primary.swiftUIColor.hexRepresentation);
        }
        """
        return (variables + style).replacingOccurrences(of: "\n", with: "")
    }()
    public static let mungeEmailScript: String? = {
        guard let mungeScript = Bundle.main.load(filename: "mungeEmail", withExtension: "js") else { return nil }
        return "const MESSAGE_SELECTOR = \"#\(divWrapperId)\"; \(mungeScript)"
    }()

    public static func isEmailAddress(_ mail: String) -> Bool {
        return emailPredicate.evaluate(with: mail.lowercased())
    }

    public static func forwardQuote(message: Message) -> String {
        let date = DateFormatter.localizedString(from: message.date, dateStyle: .medium, timeStyle: .short)
        let to = ListFormatter.localizedString(byJoining: message.to.map(\.htmlDescription))
        var cc: String {
            if !message.cc.isEmpty {
                return "<div>\(MailResourcesStrings.Localizable.ccTitle) \(ListFormatter.localizedString(byJoining: message.cc.map(\.htmlDescription)))<br></div>"
            } else {
                return ""
            }
        }
        return """
        <div class=\"forwardContentMessage\">
        <div>---------- \(MailResourcesStrings.Localizable.messageForwardHeader) ---------<br></div>
        <div>\(MailResourcesStrings.Localizable.fromTitle) \(message.from.first?.htmlDescription ?? "")<br></div>
        <div>\(MailResourcesStrings.Localizable.dateTitle) \(date)<br></div>
        <div>\(MailResourcesStrings.Localizable.subjectTitle) \(message.formattedSubject)<br></div>
        <div>\(MailResourcesStrings.Localizable.toTitle) \(to)<br></div>
        \(cc)
        <div><br></div>
        <div><br></div>
        \(message.body?.value?.replacingOccurrences(of: "'", with: "’") ?? "")
        </div>
        """
    }

    public static func replyQuote(message: Message) -> String {
        let headerText = MailResourcesStrings.Localizable.messageReplyHeader(
            DateFormatter.localizedString(from: message.date, dateStyle: .medium, timeStyle: .short),
            message.from.first?.htmlDescription ?? ""
        )
        return """
        <div id=\"answerContentMessage\" class=\"ik_mail_quote\" >
        <div>\(headerText)</div>
        <blockquote class=\"ws-ng-quote\">
        \(message.body?.value?.replacingOccurrences(of: "'", with: "’") ?? "")
        </blockquote>
        </div>
        """
    }

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

    public static let messageQuantityLimit = 500
    public static let contactSuggestionLimit = 5

    public static func longUid(from shortUid: String, folderId: String) -> String {
        return "\(shortUid)@\(folderId)"
    }

    public static func shortUid(from longUid: String) -> String {
        return longUid.components(separatedBy: "@")[0]
    }

    public static func appVersion() -> String {
        let release = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String? ?? "x.x"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String? ?? "x"
        return "kMail iOS version \(release)-beta\(build)"
    }

    public static let searchFolderId = "search_folder_id"

    public static let backgroundRefreshTaskIdentifier = "com.infomaniak.mail.background-refresh"
}
