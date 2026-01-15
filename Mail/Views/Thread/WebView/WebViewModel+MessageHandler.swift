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

import MailCore
import MailResources
import Sentry
import WebKit

extension WebViewModel: WKScriptMessageHandler {
    enum JavaScriptMessageTopic: String, CaseIterable {
        case log, sizeChanged, overScroll, error
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let event = JavaScriptMessageTopic(rawValue: message.name) else { return }
        switch event {
        case .log:
            print(message.body)
        case .sizeChanged:
            updateWebViewHeight(message)
        case .overScroll:
            sendOverScrollMessage(message)
        case .error:
            sendJavaScriptError(message)
        }
    }

    private func updateWebViewHeight(_ message: WKScriptMessage) {
        guard let data = message.body as? [String: CGFloat], let height = data["height"] else { return }

        // On some messages, the size infinitely increases by 1px ?
        // Having a threshold avoids this problem
        if Int(abs(webViewHeight - height)) > Constants.sizeChangeThreshold {
            contentLoading = false
            webViewHeight = height
        }
    }

    private func sendOverScrollMessage(_ message: WKScriptMessage) {
        guard let data = message.body as? [String: Any] else { return }

        let clientWidth = data["clientWidth"] as? CGFloat ?? .infinity
        SentrySDK.capture(message: "After zooming the mail it can still scroll.") { scope in
            scope.setTags([
                "messageUid": data["messageId"] as? String ?? "",
                "isClientWidthEmpty": String(clientWidth <= 0)
            ])
            scope.setExtras([
                "clientWidth": data["clientWidth"] as Any,
                "scrollWidth": data["scrollWidth"] as Any
            ])
        }
    }

    private func sendJavaScriptError(_ message: WKScriptMessage) {
        guard let data = message.body as? [String: Any] else { return }

        SentrySDK.capture(message: "JavaScript returned an error when displaying an email.") { scope in
            scope.setTags(["messageUid": data["messageId"] as? String ?? ""])
            scope.setExtras([
                "errorName": data["errorName"] as Any,
                "errorMessage": data["errorMessage"] as Any,
                "errorStack": data["errorStack"] as Any
            ])
        }
    }
}
