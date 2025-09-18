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
import WebKit

public final class URLSchemeHandler: NSObject, WKURLSchemeHandler {
    public static let scheme = "mail-infomaniak"
    public static let domain = "://mail.infomaniak.com"

    private var dataTasksInProgress = [Int: URLSessionDataTask]()
    private let syncQueue = DispatchQueue(label: "com.infomaniak.mail.URLSchemeHandler")

    @LazyInjectService private var accountManager: AccountManager
    @LazyInjectService private var tokenStore: TokenStore

    public func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else {
            urlSchemeTask.didFailWithError(MailError.resourceError)
            return
        }

        guard let currentAccount = accountManager.getCurrentAccount(),
              let currentAccessToken = tokenStore.tokenFor(userId: currentAccount.userId)?.apiToken.accessToken else {
            urlSchemeTask.didFailWithError(MailError.unknownError)
            return
        }

        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        components?.scheme = "https"
        var request = URLRequest(url: components!.url!)
        request.addValue(
            "Bearer \(currentAccessToken)",
            forHTTPHeaderField: "Authorization"
        )
        let dataTask = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            self?.syncQueue.sync {
                guard (error as? URLError)?.code != .cancelled,
                      self?.dataTasksInProgress[urlSchemeTask.hash] != nil
                else { return }

                self?.dataTasksInProgress[urlSchemeTask.hash] = nil
                if let error {
                    urlSchemeTask.didFailWithError(error)
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse,
                      (200 ... 299).contains(httpResponse.statusCode),
                      data?.isEmpty == false else {
                    urlSchemeTask.didFailWithError(MailError.resourceError)
                    return
                }

                if let response {
                    urlSchemeTask.didReceive(response)
                }
                if let data {
                    urlSchemeTask.didReceive(data)
                    urlSchemeTask.didFinish()
                }
            }
        }
        dataTasksInProgress[urlSchemeTask.hash] = dataTask
        dataTask.resume()
    }

    public func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        syncQueue.sync {
            dataTasksInProgress[urlSchemeTask.hash]?.cancel()
            dataTasksInProgress[urlSchemeTask.hash] = nil
        }
    }
}
