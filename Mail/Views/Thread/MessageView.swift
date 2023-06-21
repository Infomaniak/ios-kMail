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

import CocoaLumberjackSwift
import InfomaniakCore
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailResources
import RealmSwift
import SwiftUI

/// Something that can display an email
struct MessageView: View {
    @LazyInjectService var matomo: MatomoUtils

    @EnvironmentObject var mailboxManager: MailboxManager

    @ObservedObject var viewModel: MessageSelectionViewModel

    @State var presentableBody: PresentableBody
    @State var isHeaderExpanded = false
    @State var isMessageExpanded: Bool

    /// True once we finished preprocessing the content
    @State var isMessagePreprocessed = false

    /// The cancellable task used to preprocess the content
    @State var preprocessing: Task<Void, Never>?

    @State var displayContentBlockedActionView = false

    @ObservedRealmObject var message: Message

    /// Something to base64 encode images
    let base64Encoder = Base64Encoder()

    private var isRemoteContentBlocked: Bool {
        return (UserDefaults.shared.displayExternalContent == .askMe || message.folder?.role == .spam)
            && !message.localSafeDisplay
    }

    init(message: Message, viewModel: MessageSelectionViewModel) {
        self.message = message
        self.viewModel = viewModel
        presentableBody = PresentableBody(message: message)
        isMessageExpanded = viewModel.expanded(forMessage: message)
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                MessageHeaderView(
                    message: message,
                    isHeaderExpanded: $isHeaderExpanded,
                    isMessageExpanded: $isMessageExpanded
                )
                .padding(.horizontal, 16)

                let _ = print("••isMessageExpanded :\(isMessageExpanded)")
                
                if isMessageExpanded {
                    if isRemoteContentBlocked && displayContentBlockedActionView {
                        MessageHeaderActionView(
                            icon: MailResourcesAsset.emailActionWarning.swiftUIImage,
                            message: MailResourcesStrings.Localizable.alertBlockedImagesDescription
                        ) {
                            MailButton(label: MailResourcesStrings.Localizable.alertBlockedImagesDisplayContent) {
                                withAnimation {
                                    $message.localSafeDisplay.wrappedValue = true
                                }
                            }
                            .mailButtonStyle(.smallLink)
                        }
                    }

                    if !message.attachments.filter({ $0.disposition == .attachment || $0.contentId == nil }).isEmpty {
                        AttachmentsView(message: message)
                            .padding(.top, 24)
                    }

                    MessageBodyView(
                        isMessagePreprocessed: isMessagePreprocessed,
                        presentableBody: $presentableBody,
                        blockRemoteContent: isRemoteContentBlocked,
                        displayContentBlockedActionView: $displayContentBlockedActionView,
                        messageUid: message.uid
                    )
                    .padding(.top, 16)
                }
            }
            .padding(.vertical, 16)
            .task {
                if self.message.shouldComplete {
                    await fetchMessage()
                }
            }
            .onChange(of: message.fullyDownloaded) { _ in
                if message.fullyDownloaded, isMessageExpanded {
                    prepareBodyIfNeeded()
                }
            }
            .onChange(of: isMessageExpanded) { _ in
                // bump viewModel
                self.viewModel.changeExpanded(forMessageUid: self.message.uid, isExpanded: isMessageExpanded)
                
                if message.fullyDownloaded, isMessageExpanded {
                    prepareBodyIfNeeded()
                } else {
                    cancelPrepareBodyIfNeeded()
                }
            }
            .onAppear {
                if message.fullyDownloaded,
                   isMessageExpanded,
                   !isMessagePreprocessed,
                   preprocessing == nil {
                    prepareBodyIfNeeded()
                }
            }
            .onDisappear {
                cancelPrepareBodyIfNeeded()
            }
        }
    }

    @MainActor private func fetchMessage() async {
        await tryOrDisplayError {
            do {
                try await mailboxManager.message(message: message)
            } catch let error as MailApiError where error == .apiMessageNotFound {
                try await mailboxManager.refreshFolder(from: [message])
            }
        }
    }

    /// Update the DOM in the main actor
    @MainActor func mutate(compactBody: String?, quote: String?) {
        presentableBody.compactBody = compactBody
        presentableBody.quote = quote
    }

    /// Update the DOM in the main actor
    @MainActor func mutate(body: String?, compactBody: String?) {
        presentableBody.body?.value = body
        presentableBody.compactBody = compactBody
    }

    /// preprocess is finished
    @MainActor func processingCompleted() {
        isMessagePreprocessed = true
    }
}

// struct MessageView_Previews: PreviewProvider {
//    static let stateTrue = State(initialValue: true)
//    static let bindingTrue = Binding(projectedValue: stateTrue)
//    static let stateFalse = State(initialValue: false)
//    static let bindingFalse = Binding(projectedValue: stateFalse)
//
//    static var previews: some View {
//
//        Group {
//            MessageView(message: PreviewHelper.sampleMessage, isMessageExpanded: self.$stateTrue)
//
//            MessageView(message: PreviewHelper.sampleMessage, isMessageExpanded: self.$stateFalse)
//        }
//        .previewLayout(.sizeThatFits)
//    }
// }
