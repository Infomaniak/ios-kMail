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

actor TaskProgressHandler {
    private var dataTasksInProgress = [String: URLSessionDataTask]()
    private var urlSchemeTasksInProgress = [String: WKURLSchemeTask]()

    func addDataTask(_ task: URLSessionDataTask, for url: URL) {
        dataTasksInProgress[url.absoluteString] = task
    }

    func cancelDataTask(for url: URL) {
        dataTasksInProgress[url.absoluteString]?.cancel()
        urlSchemeTasksInProgress[url.absoluteString] = nil
    }

    func addURLSchemeTask(_ urlSchemeTask: WKURLSchemeTask, for url: URL) {
        urlSchemeTasksInProgress[url.absoluteString] = urlSchemeTask
    }

    func didReceive(_ response: URLResponse, for url: URL) {
        urlSchemeTasksInProgress[url.absoluteString]?.didReceive(response)
    }

    func didReceive(_ data: Data, for url: URL) {
        urlSchemeTasksInProgress[url.absoluteString]?.didReceive(data)
    }

    func didFinish(for url: URL) {
        urlSchemeTasksInProgress[url.absoluteString]?.didFinish()
        urlSchemeTasksInProgress[url.absoluteString] = nil
    }

    func didFailWithError(_ error: Error, for url: URL) {
        urlSchemeTasksInProgress[url.absoluteString]?.didFailWithError(error)
        urlSchemeTasksInProgress[url.absoluteString] = nil
    }
}

public class URLSchemeHandler: NSObject, WKURLSchemeHandler {
    public static let scheme = "mail-infomaniak"
    public static let domain = "://mail.infomaniak.com"

    private let taskProgressHandler = TaskProgressHandler()

    public func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else { return }
        Task {
            await taskProgressHandler.cancelDataTask(for: url)
            await taskProgressHandler.addURLSchemeTask(urlSchemeTask, for: url)

            var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
            components?.scheme = "https"
            var request = URLRequest(url: components!.url!)
            request.addValue(
                "Bearer \(AccountManager.instance.currentAccount.token.accessToken)",
                forHTTPHeaderField: "Authorization"
            )
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                Task { [weak self] in
                    guard (error as? URLError)?.code != .cancelled else { return }

                    if let response = response {
                        await self?.taskProgressHandler.didReceive(response, for: url)
                    }
                    if let data = data {
                        await self?.taskProgressHandler.didReceive(data, for: url)
                        await self?.taskProgressHandler.didFinish(for: url)
                    }
                    if let error = error {
                        await self?.taskProgressHandler.didFailWithError(error, for: url)
                    }
                }
            }
            await taskProgressHandler.addDataTask(task, for: url)
            task.resume()
        }
    }

    public func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else { return }
        Task {
            await taskProgressHandler.cancelDataTask(for: url)
        }
    }
}
