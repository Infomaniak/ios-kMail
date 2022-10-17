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
import WebKit

public class URLSchemeHandler: NSObject, WKURLSchemeHandler {
    public static let scheme = "mail-infomaniak"
    public static let domain = "://mail.infomaniak.com"

    private var tasksInProgress = [String: URLSessionDataTask]()

    public func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else { return }
        tasksInProgress[url.absoluteString]?.cancel()

        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        components?.scheme = "https"
        var request = URLRequest(url: components!.url!)
        request.addValue(
            "Bearer \(AccountManager.instance.currentAccount.token.accessToken)",
            forHTTPHeaderField: "Authorization"
        )
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard (error as? URLError)?.code != .cancelled else { return }

            if let response = response {
                urlSchemeTask.didReceive(response)
            }
            if let data = data {
                urlSchemeTask.didReceive(data)
                urlSchemeTask.didFinish()
            }
            if let error = error {
                urlSchemeTask.didFailWithError(error)
            }
        }
        tasksInProgress[url.absoluteString] = task
        task.resume()
    }

    public func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else { return }
        tasksInProgress[url.absoluteString]?.cancel()
    }
}
