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

import InfomaniakCoreCommonUI
import InfomaniakDI
import MailCore
import MailCoreUI
import RealmSwift
import SwiftSoup
import SwiftUI

struct MessageBodyContentView: View {
    @StateObject private var model = WebViewModel()

    @Binding var displayContentBlockedActionView: Bool
    @Binding var initialContentLoading: Bool

    let presentableBody: PresentableBody?
    let blockRemoteContent: Bool
    let messageUid: String

    private let printNotificationPublisher = NotificationCenter.default.publisher(for: Notification.Name.printNotification)

    var body: some View {
        ZStack {
            VStack {
                if let presentableBody, presentableBody.body != nil {
                    WebView(webView: model.webView, messageUid: messageUid) {
                        loadBody(blockRemoteContent: blockRemoteContent, presentableBody: presentableBody)
                    }
                    .frame(height: model.webViewHeight)
                    .onAppear {
                        loadBody(blockRemoteContent: blockRemoteContent, presentableBody: presentableBody)
                    }
                    .onChange(of: presentableBody) { newValue in
                        loadBody(blockRemoteContent: blockRemoteContent, presentableBody: newValue)
                    }
                    .onChange(of: model.showBlockQuote) { _ in
                        loadBody(blockRemoteContent: blockRemoteContent, presentableBody: presentableBody)
                    }
                    .onChange(of: blockRemoteContent) { newValue in
                        loadBody(blockRemoteContent: newValue, presentableBody: presentableBody)
                    }

                    if !presentableBody.quotes.isEmpty {
                        ShowBlockquoteButton(showBlockquote: $model.showBlockQuote)
                    }
                }
            }
            .opacity(model.initialContentLoading ? 0 : 1)

            if model.initialContentLoading {
                ShimmerView()
            }
        }
        .onReceive(printNotificationPublisher) { _ in
            printMessage()
        }
        .onChange(of: model.initialContentLoading) { _ in
            initialContentLoading = model.initialContentLoading
        }
    }

    private func printMessage() {
        let printController = UIPrintInteractionController.shared
        let printFormatter = model.webView.viewPrintFormatter()
        printController.printFormatter = printFormatter

        let completionHandler: UIPrintInteractionController.CompletionHandler = { _, completed, error in
            @InjectService var snackbarPresenter: IKSnackBarPresentable
            @InjectService var matomo: MatomoUtils

            if completed {
                matomo.track(eventWithCategory: .bottomSheetMessageActions, name: "printValidated")
            } else if let error {
                snackbarPresenter.show(message: error.localizedDescription)
            } else {
                matomo.track(eventWithCategory: .bottomSheetMessageActions, name: "printCancelled")
            }
        }

        Task { @MainActor in
            printController.present(animated: true, completionHandler: completionHandler)
        }
    }

    private func loadBody(blockRemoteContent: Bool, presentableBody: PresentableBody?) {
        guard let presentableBody else { return }

        Task {
            let loadResult = await model.loadBody(presentableBody: presentableBody, blockRemoteContent: blockRemoteContent)
            displayContentBlockedActionView = (loadResult == .remoteContentBlocked)
        }
    }
}

#Preview {
    MessageBodyContentView(
        displayContentBlockedActionView: .constant(false),
        initialContentLoading: .constant(false),
        presentableBody: PreviewHelper.samplePresentableBody,
        blockRemoteContent: false,
        messageUid: "message_uid"
    )
}
