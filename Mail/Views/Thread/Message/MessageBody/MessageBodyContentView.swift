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

import IKSnackbar
import InfomaniakCoreCommonUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import Nuke
import RealmSwift
import SwiftSoup
import SwiftUI

struct MessageBodyContentView: View {
    @LazyInjectService private var snackbarPresenter: IKSnackBarPresentable

    @Environment(\.currentUser) private var currentUser

    @EnvironmentObject private var mailboxManager: MailboxManager
    @EnvironmentObject private var mainViewState: MainViewState

    @StateObject private var model: WebViewModel

    @Binding private var displayContentBlockedActionView: Bool
    @Binding private var initialContentLoading: Bool

    @State private var mentionMenuContent: MentionMenuContent?

    private let presentableBody: PresentableBody?
    private let blockRemoteContent: Bool
    private let messageUid: String

    private let printNotificationPublisher = NotificationCenter.default.publisher(for: Notification.Name.printNotification)

    init(
        displayContentBlockedActionView: Binding<Bool>,
        initialContentLoading: Binding<Bool>,
        presentableBody: PresentableBody?,
        blockRemoteContent: Bool,
        messageUid: String,
        messageTheme: MessageTheme,
        mailboxAliases: [String]
    ) {
        _displayContentBlockedActionView = displayContentBlockedActionView
        _initialContentLoading = initialContentLoading
        self.presentableBody = presentableBody
        self.blockRemoteContent = blockRemoteContent
        self.messageUid = messageUid

        _model = StateObject(wrappedValue: WebViewModel(theme: messageTheme, aliases: mailboxAliases))
    }

    var body: some View {
        ZStack {
            VStack {
                if let presentableBody, presentableBody.body != nil {
                    WebView(
                        webView: model.webView,
                        messageUid: messageUid,
                        mentionMenuContent: $mentionMenuContent
                    ) {
                        loadBody(blockRemoteContent: blockRemoteContent, presentableBody: presentableBody)
                    }
                    .frame(height: model.webViewHeight)
                    .onAppear {
                        loadBody(blockRemoteContent: blockRemoteContent, presentableBody: presentableBody)
                    }
                    .onChange(of: model.tappedMention) { mention in
                        guard let mention else { return }
                        Task {
                            let menu = await buildMentionMenu(for: mention)
                            mentionMenuContent = menu
                            model.tappedMention = nil
                        }
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

    private func buildMentionMenu(for mention: WebViewModel.TappedMention) async -> MentionMenuContent {
        let recipient = Recipient(email: mention.email, name: mention.name)
        let title: String
        let subtitle: String?
        if mention.name.isEmpty || mention.name == mention.email {
            title = mention.email
            subtitle = nil
        } else {
            title = mention.name
            subtitle = mention.email
        }

        let image = await mentionAvatarImage(for: recipient)

        let canSendEmails = mailboxManager.mailbox.permissions?.canSendEmails ?? true
        let isRemote = mailboxManager.contactManager.getContact(for: recipient)?.isRemote == true

        var actions = [MentionMenuAction]()

        actions.append(MentionMenuAction(
            title: MailResourcesStrings.Localizable.contactActionWriteEmail,
            image: actionImage(for: .writeEmailAction),
            isDisabled: !canSendEmails
        ) {
            mainViewState.composeMessageIntent = .writeTo(recipient: recipient, originMailboxManager: mailboxManager)
        })

        if !isRemote {
            actions.append(MentionMenuAction(
                title: MailResourcesStrings.Localizable.contactActionAddToContacts,
                image: actionImage(for: .addContactsAction)
            ) {
                Task {
                    await tryOrDisplayError {
                        try await mailboxManager.contactManager.addContact(recipient: recipient)
                        snackbarPresenter.show(message: MailResourcesStrings.Localizable.snackbarContactSaved)
                    }
                }
            })
        }

        actions.append(MentionMenuAction(
            title: MailResourcesStrings.Localizable.contactActionCopyEmailAddress,
            image: actionImage(for: .copyEmailAction)
        ) {
            UIPasteboard.general.string = recipient.email
        })

        return MentionMenuContent(title: title, subtitle: subtitle, image: image, rect: mention.rect, actions: actions)
    }

    private func actionImage(for action: Action) -> UIImage? {
        UIImage(named: action.iconName, in: MailResourcesResources.bundle, with: nil)
    }

    @MainActor
    private func mentionAvatarImage(for recipient: Recipient) async -> UIImage? {
        let avatarConfiguration = ContactConfiguration.correspondent(
            correspondent: recipient,
            associatedBimi: nil,
            contextUser: currentUser.value,
            contextMailboxManager: mailboxManager
        )

        let contact = CommonContactCache.getOrCreateContact(contactConfiguration: avatarConfiguration)
        if let token = mailboxManager.apiFetcher.currentToken,
           let authenticatedRequest = contact.avatarImageRequest.authenticatedRequestIfNeeded(
               token: token,
               processors: [.circle()]
           ) {
            let task = ImagePipeline.shared.imageTask(with: authenticatedRequest)
            if let remoteImage = try? await task.image {
                return remoteImage.withRenderingMode(.alwaysOriginal)
            }
        }

        let renderer = ImageRenderer(content: AvatarView(
            mailboxManager: mailboxManager,
            contactConfiguration: avatarConfiguration,
            size: RecipientHeaderCell.defaultAvatarSize
        ))
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage?.withRenderingMode(.alwaysOriginal)
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
        messageUid: "message_uid",
        messageTheme: .auto,
        mailboxAliases: []
    )
}
