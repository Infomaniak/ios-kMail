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

import CocoaLumberjackSwift
import InfomaniakCore
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import RealmSwift
import SwiftUI
import SwiftUIMacros

extension EnvironmentValues {
    @EnvironmentKey
    var isMessageInteractive = true
}

/// Something that can display an email
struct MessageView: View {
    @LazyInjectService private var snackbarPresenter: SnackBarPresentable

    @Environment(\.isMessageInteractive) private var isMessageInteractive

    @EnvironmentObject var mailboxManager: MailboxManager

    @State var presentableBody: PresentableBody
    @State var isHeaderExpanded = false
    @State var isMessageExpanded: Bool
    @Binding private var threadForcedExpansion: [String: MessageExpansionType]

    /// True once we finished preprocessing the content
    @State var isMessagePreprocessed = false

    @State private var isShowingErrorLoading = false

    @State var displayContentBlockedActionView = false

    @ObservedRealmObject var message: Message

    /// Something to preprocess inline attachments
    let inlineAttachmentWorker: InlineAttachmentWorker

    private var isRemoteContentBlocked: Bool {
        return (UserDefaults.shared.displayExternalContent == .askMe || message.folder?.role == .spam)
            && !message.localSafeDisplay
    }

    init(message: Message, isMessageExpanded: Bool = false, threadForcedExpansion: Binding<[String: MessageExpansionType]>) {
        self.message = message
        presentableBody = PresentableBody(message: message)
        self.isMessageExpanded = isMessageExpanded
        _threadForcedExpansion = threadForcedExpansion
        inlineAttachmentWorker = InlineAttachmentWorker(messageUid: message.uid)
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                MessageHeaderView(message: message, isHeaderExpanded: $isHeaderExpanded, isMessageExpanded: $isMessageExpanded)

                if isMessageExpanded {
                    VStack(spacing: UIPadding.regular) {
                        if isMessageInteractive {
                            MessageSubHeaderView(
                                message: message,
                                displayContentBlockedActionView: $displayContentBlockedActionView
                            )
                        }

                        if isShowingErrorLoading {
                            Text(MailResourcesStrings.Localizable.errorLoadingMessage)
                                .textStyle(.bodySmallItalicSecondary)
                                .padding(.horizontal, value: .regular)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            MessageBodyView(
                                presentableBody: $presentableBody,
                                blockRemoteContent: isRemoteContentBlocked,
                                displayContentBlockedActionView: $displayContentBlockedActionView,
                                messageUid: message.uid
                            )
                        }
                    }
                }
            }
            .onAppear {
                prepareBodyIfNeeded()
            }
            .task {
                await fetchMessageAndEventCalendar()
            }
            .task {
                for await _ in inlineAttachmentWorker.objectWillChange.values {
                    debugPrint("inlineAttachmentWorker did change :\(message.uid)")
                    guard let updatedBody = inlineAttachmentWorker.presentableBody else {
                        return
                    }
                    self.isMessagePreprocessed = true
                    self.presentableBody = updatedBody
                }
            }
            .task(id: isMessageExpanded) {
                await fetchMessageAndEventCalendar()
            }
            .onDisappear {
                inlineAttachmentWorker.stop()
            }
            .onChange(of: message.fullyDownloaded) { _ in
                prepareBodyIfNeeded()
            }
            .onChange(of: isMessageExpanded) { _ in
                prepareBodyIfNeeded()
            }
            .onChange(of: presentableBody) { _ in
                print("presentable body changed \(message.uid)")
            }
            .onChange(of: threadForcedExpansion[message.uid]) { newValue in
                if newValue == .expanded {
                    withAnimation {
                        isMessageExpanded = true
                    }
                }
            }
            .accessibilityAction(named: MailResourcesStrings.Localizable.expandMessage) {
                guard isMessageInteractive else { return }
                withAnimation {
                    isMessageExpanded.toggle()
                }
            }
        }
    }

    private func fetchMessageAndEventCalendar() async {
        guard isMessageExpanded else { return }

        async let fetchMessageResult: Void = fetchMessage()

        async let fetchEventCalendar: Void = fetchEventCalendar()

        await fetchMessageResult
        await fetchEventCalendar
    }

    private func fetchMessage() async {
        guard message.shouldComplete else { return }

        await tryOrDisplayError {
            do {
                try await mailboxManager.message(message: message)
            } catch let error as MailApiError where error == .apiMessageNotFound {
                snackbarPresenter.show(message: error.errorDescription ?? "")
                try await mailboxManager.refreshFolder(from: [message], additionalFolder: nil)
            } catch let error as AFErrorWithContext where error.afError.isExplicitlyCancelledError {
                isShowingErrorLoading = false
            } catch {
                isShowingErrorLoading = true
            }
        }
    }

    private func fetchEventCalendar() async {
        try? await mailboxManager.calendarEvent(from: message.uid)
    }
}

#Preview("Message collapsed") {
    MessageView(
        message: PreviewHelper.sampleMessage,
        threadForcedExpansion: .constant([PreviewHelper.sampleMessage.uid: .collapsed])
    )
    .environmentObject(PreviewHelper.sampleMailboxManager)
    .previewLayout(.sizeThatFits)
}

#Preview("Message expanded") {
    MessageView(
        message: PreviewHelper.sampleMessage,
        isMessageExpanded: true,
        threadForcedExpansion: .constant([PreviewHelper.sampleMessage.uid: .expanded])
    )
    .environmentObject(PreviewHelper.sampleMailboxManager)
    .previewLayout(.sizeThatFits)
}
