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

import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import RealmSwift
import SwiftSoup
import SwiftUI

struct MessageBodyView: View {
    @LazyInjectService private var matomo: MatomoUtils
    @LazyInjectService private var snackbarPresenter: SnackBarPresentable

    @State private var textPlainHeight = CGFloat.zero

    @StateObject private var model = WebViewModel()

    let isMessagePreprocessed: Bool
    @Binding var presentableBody: PresentableBody
    var blockRemoteContent: Bool
    @Binding var displayContentBlockedActionView: Bool

    let messageUid: String

    private let printNotificationPublisher = NotificationCenter.default.publisher(for: Notification.Name.printNotification)

    var body: some View {
        ZStack {
            VStack {
                if presentableBody.body != nil {
                    WebView(model: model, messageUid: messageUid)
                        .frame(height: model.webViewHeight)
                        .onAppear {
                            loadBody(blockRemoteContent: blockRemoteContent)
                        }
                        .onChange(of: presentableBody) { _ in
                            loadBody(blockRemoteContent: blockRemoteContent)
                        }
                        .onChange(of: model.showBlockQuote) { _ in
                            loadBody(blockRemoteContent: blockRemoteContent)
                        }
                        .onChange(of: blockRemoteContent) { newValue in
                            loadBody(blockRemoteContent: newValue)
                        }

                    if !presentableBody.quotes.isEmpty {
                        Button(model.showBlockQuote
                            ? MailResourcesStrings.Localizable.messageHideQuotedText
                            : MailResourcesStrings.Localizable.messageShowQuotedText) {
                                model.showBlockQuote.toggle()
                            }
                            .buttonStyle(.ikLink(isInlined: true))
                            .controlSize(.small)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, value: .regular)
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
    }

    func printMessage() {
        let printController = UIPrintInteractionController.shared
        let printFormatter = model.webView.viewPrintFormatter()
        printController.printFormatter = printFormatter

        let completionHandler: UIPrintInteractionController.CompletionHandler = { _, completed, error in
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

    private func loadBody(blockRemoteContent: Bool) {
        Task {
            let loadResult = try await model.loadBody(
                presentableBody: presentableBody,
                blockRemoteContent: blockRemoteContent,
                messageUid: messageUid
            )

            displayContentBlockedActionView = (loadResult == .remoteContentBlocked)
        }
    }
}

#Preview {
    MessageBodyView(
        isMessagePreprocessed: true,
        presentableBody: .constant(PreviewHelper.samplePresentableBody),
        blockRemoteContent: false,
        displayContentBlockedActionView: .constant(false),
        messageUid: "message_uid"
    )
}
