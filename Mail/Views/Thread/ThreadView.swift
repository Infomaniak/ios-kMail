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

import InfomaniakCore
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailResources
import RealmSwift
import SwiftUI

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero

    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
        // No need to implement it
    }
}

struct ThreadView: View {
    @LazyInjectService private var matomo: MatomoUtils

    @Environment(\.isCompactWindow) private var isCompactWindow
    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject private var mailboxManager: MailboxManager
    @EnvironmentObject private var actionsManager: ActionsManager

    @State private var headerHeight: CGFloat = 0
    @State private var displayNavigationTitle = false
    @State private var replyOrReplyAllMessage: Message?

    @StateObject private var alert = NewMessageAlert()

    @ObservedRealmObject var thread: Thread

    private let toolbarActions: [Action] = [.reply, .forward, .archive, .delete]

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

                VStack(alignment: .leading, spacing: 8) {
                    Text(thread.formattedSubject)
                        .textStyle(.header2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(8)

                    let externalTag = thread.displayExternalRecipientState(mailboxManager: mailboxManager, recipientsList: thread.from)
                    switch externalTag {
                    case .many, .one:
                        Button {
                            alert.state = .externalRecipient(state: externalTag)
                        } label: {
                            Text(MailResourcesStrings.Localizable.externalTag)
                                .foregroundColor(MailResourcesAsset.onTagColor.swiftUIColor)
                                .textStyle(.labelMedium)
                                .padding(4)
                                .background(MailResourcesAsset.yellowColor.swiftUIColor)
                                .cornerRadius(2)
                        }
                    case .none:
                        EmptyView()
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 16)
                .padding(.horizontal, 16)

                MessageListView(messages: thread.messages)
            }
        }
        .background(MailResourcesAsset.backgroundColor.swiftUIColor)
        .coordinateSpace(name: "scrollView")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
            displayNavigationTitle = offset.y < -85
        }
        .onAppear {
            matomo.track(
                eventWithCategory: .userInfo,
                action: .data,
                name: "nbMessagesInThread",
                value: Float(thread.messages.count)
            )
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
                        try await actionsManager.performAction(
                            target: messages,
                            action: thread.flagged ? .unstar : .star,
                            origin: .toolbar(originFolder: originFolder)
                        )
                    }
                } label: {
                    (thread.flagged ? MailResourcesAsset.starFull : MailResourcesAsset.star).swiftUIImage
                        .foregroundColor(thread.flagged ? MailResourcesAsset.yellowColor.swiftUIColor : .accentColor)
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
                    .disabled(action == .archive && thread.folder?.role == .archive)
                }
                Spacer()
            }
            ActionsPanelButton(messages: thread.messages.toArray(), originFolder: thread.folder) {
                ToolbarButtonLabel(text: MailResourcesStrings.Localizable.buttonMore,
                                   icon: MailResourcesAsset.plusActions.swiftUIImage)
            }
            .frame(maxWidth: .infinity)
        }
        .onChange(of: thread.messages) { newMessagesList in
            guard isCompactWindow, newMessagesList.isEmpty || thread.messageInFolderCount == 0 else {
                return
            }

            // Dismiss on iPhone only
            dismiss()
        }
        .customAlert(isPresented: $alert.isShowing) {
            switch alert.state {
            case .externalRecipient(let state):
                ExternalRecipientView(externalTagSate: state, isDraft: false)
            default:
                EmptyView()
            }
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

        let originFolder = thread.folder?.freezeIfNeeded()
        Task {
            try await actionsManager.performAction(
                target: messages,
                action: action,
                origin: .toolbar(originFolder: originFolder)
            )
            if action == .archive || action == .delete {
                dismiss()
            }
        }
    }
}

struct VerticalLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: 4) {
            configuration.icon
            configuration.title
        }
    }
}

extension LabelStyle where Self == VerticalLabelStyle {
    static var vertical: VerticalLabelStyle { .init() }
}

extension Label {
    @ViewBuilder
    func dynamicLabelStyle(sizeClass: UserInterfaceSizeClass) -> some View {
        if sizeClass == .compact {
            labelStyle(.iconOnly)
        } else {
            labelStyle(.vertical)
        }
    }
}

struct ThreadView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadView(thread: PreviewHelper.sampleThread)
            .environmentObject(PreviewHelper.sampleMailboxManager)
    }
}
