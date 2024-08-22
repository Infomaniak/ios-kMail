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

import InfomaniakCore
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import RealmSwift
import SwiftModalPresentation
import SwiftUI
import WrappingHStack

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero

    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
        // No need to implement it
    }
}

struct ThreadView: View {
    private static let standardActions: [Action] = [.reply, .forward, .archive, .delete]
    private static let archiveActions: [Action] = [.reply, .forward, .openMovePanel, .delete]

    @LazyInjectService private var matomo: MatomoUtils

    @EnvironmentObject private var mailboxManager: MailboxManager
    @EnvironmentObject private var actionsManager: ActionsManager

    @State private var displayNavigationTitle = false
    @State private var replyOrReplyAllMessage: Message?
    @State private var messagesToMove: [Message]?

    @ModalState private var isShowingExternalTagAlert = false
    @ModalState private var nearestFlushAlert: FlushAlertState?

    @ObservedRealmObject var thread: Thread

    private var toolbarActions: [Action] {
        thread.folder?.role == .archive ? Self.archiveActions : Self.standardActions
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: proxy.frame(in: .named("scrollView")).origin
                    )
                }
                .frame(width: 0, height: 0)

                VStack(alignment: .leading, spacing: IKPadding.small) {
                    Text(thread.formattedSubject)
                        .textStyle(.header2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(8)

                    WrappingHStack(lineSpacing: IKPadding.small) {
                        let externalTag = thread.displayExternalRecipientState(
                            mailboxManager: mailboxManager,
                            recipientsList: thread.from
                        )
                        if externalTag.shouldDisplay {
                            Button {
                                matomo.track(eventWithCategory: .externals, name: "threadTag")
                                isShowingExternalTagAlert = true
                            } label: {
                                Text(MailResourcesStrings.Localizable.externalTag)
                                    .tagModifier(
                                        foregroundColor: MailResourcesAsset.onTagExternalColor,
                                        backgroundColor: MailResourcesAsset.yellowColor
                                    )
                            }
                            .customAlert(isPresented: $isShowingExternalTagAlert) {
                                ExternalRecipientView(externalTagSate: externalTag, isDraft: false)
                            }
                        }

                        MessageFolderTag(title: thread.searchFolderName, inThreadHeader: true)
                    }
                }
                .padding(.top, value: .small)
                .padding(.bottom, value: .medium)
                .padding(.horizontal, value: .medium)

                MessageListView(messages: thread.messages.toArray())
            }
        }
        .background(MailResourcesAsset.backgroundColor.swiftUIColor)
        .coordinateSpace(name: "scrollView")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
            displayNavigationTitle = offset.y < -85
        }
        .onAppear {
            matomo.trackThreadInfo(of: thread)
        }
        .task {
            await markThreadAsReadIfNeeded(thread: thread)
        }
        .onChange(of: thread) { newValue in
            guard newValue.uid != thread.uid else { return }
            Task {
                await markThreadAsReadIfNeeded(thread: newValue)
            }
        }
        .navigationTitle(displayNavigationTitle ? thread.formattedSubject : "")
        .navigationBarThreadViewStyle(appearance: displayNavigationTitle ? BarAppearanceConstants
            .threadViewNavigationBarScrolledAppearance : BarAppearanceConstants.threadViewNavigationBarAppearance)
        .backButtonDisplayMode(.minimal)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    let messages = thread.messages.freeze().toArray()
                    let originFolder = thread.folder?.freezeIfNeeded()
                    Task {
                        await tryOrDisplayError {
                            try await actionsManager.performAction(
                                target: messages,
                                action: thread.flagged ? .unstar : .star,
                                origin: .toolbar(originFolder: originFolder)
                            )
                        }
                    }
                } label: {
                    (thread.flagged ? MailResourcesAsset.starFull : MailResourcesAsset.star)
                        .swiftUIImage
                        .foregroundStyle(thread.flagged ? MailResourcesAsset.yellowColor.swiftUIColor : .accentColor)
                }
            }
        }
        .bottomBar {
            ForEach(toolbarActions) { action in
                if action == .reply {
                    ToolbarButton(text: action.title, icon: action.icon) {
                        didTap(action: action)
                    }
                    .adaptivePanel(item: $replyOrReplyAllMessage) { message in
                        ReplyActionsView(message: message)
                    }
                } else {
                    ToolbarButton(text: action.title, icon: action.icon) {
                        didTap(action: action)
                    }
                    .sheet(item: $messagesToMove) { messages in
                        MoveEmailView(mailboxManager: mailboxManager, movedMessages: messages, originFolder: thread.folder)
                            .sheetViewStyle()
                    }
                }
            }
            ActionsPanelButton(messages: thread.messages.toArray(), originFolder: thread.folder, panelSource: .messageList) {
                ToolbarButtonLabel(text: MailResourcesStrings.Localizable.buttonMore,
                                   icon: MailResourcesAsset.plusActions.swiftUIImage)
            }
        }
        .customAlert(item: $nearestFlushAlert) { item in
            FlushFolderAlertView(flushAlert: item)
        }
        .matomoView(view: [MatomoUtils.View.threadView.displayName, "Main"])
    }

    private func markThreadAsReadIfNeeded(thread: Thread) async {
        guard thread.hasUnseenMessages else { return }

        let originFolder = thread.folder?.freezeIfNeeded()
        try? await actionsManager.performAction(
            target: thread.messages.toArray(),
            action: .markAsRead,
            origin: .toolbar(originFolder: originFolder)
        )
    }

    private func didTap(action: Action) {
        matomo.track(eventWithCategory: .threadActions, name: action.matomoName)

        let messages = thread.messages.freezeIfNeeded().toArray()

        if action == .reply,
           let message = messages.lastMessageToExecuteAction(currentMailboxEmail: mailboxManager.mailbox.email),
           message.canReplyAll(currentMailboxEmail: mailboxManager.mailbox.email) {
            replyOrReplyAllMessage = message
            return
        }

        if action == .openMovePanel {
            messagesToMove = messages
        }

        let originFolder = thread.folder?.freezeIfNeeded()
        Task {
            await tryOrDisplayError {
                try await actionsManager.performAction(
                    target: messages,
                    action: action,
                    origin: .toolbar(originFolder: originFolder, nearestFlushAlert: $nearestFlushAlert)
                )
            }
        }
    }
}

#Preview {
    ThreadView(thread: PreviewHelper.sampleThread)
        .environmentObject(PreviewHelper.sampleMailboxManager)
}
