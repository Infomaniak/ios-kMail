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

class MessageBottomSheet: DisplayedFloatingPanelState<MessageBottomSheet.State> {
    enum State: Equatable {
        case contact(Recipient, isRemote: Bool)
        case replyOption(Message, isThread: Bool)
    }
}

struct ThreadView: View {
    let mailboxManager: MailboxManager
    @ObservedRealmObject var thread: Thread

    @State private var headerHeight: CGFloat = 0
    @State private var displayNavigationTitle = false
    @State private var messageReply: MessageReply?

    @StateObject private var moveSheet = MoveSheet()
    @StateObject private var bottomSheet = MessageBottomSheet()
    @StateObject private var threadBottomSheet = ThreadBottomSheet()

    @EnvironmentObject var globalBottomSheet: GlobalBottomSheet
    @Environment(\.verticalSizeClass) var sizeClass
    @Environment(\.dismiss) var dismiss

    private let toolbarActions: [Action] = [.reply, .forward, .archive, .delete]

    private var messages: [Message] {
        return Array(thread.messages)
    }
    private var threadBackground: Color {
        messages.count > 1
            ? MailResourcesAsset.backgroundCardColor.swiftUiColor
            : MailResourcesAsset.backgroundColor.swiftUiColor
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: geometry.frame(in: .named("scrollView")).origin
                    )
                }
                .frame(width: 0, height: 0)

                Text(thread.formattedSubject)
                    .textStyle(.header2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(8)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                    .padding(.horizontal, 16)
                    .background(MailResourcesAsset.backgroundColor.swiftUiColor)

                LazyVStack(spacing: 0) {
                    ForEach(messages.indices, id: \.self) { index in
                        let isMessageExpanded = ((index == messages.count - 1) && !messages[index].isDraft) || !messages[index].seen
                        MessageView(message: messages[index], isMessageExpanded: isMessageExpanded)
                    }
                }
                .padding(.top, 8)
                .background(threadBackground)
            }
        }
        .coordinateSpace(name: "scrollView")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
            displayNavigationTitle = offset.y < -85
        }
        .onAppear {
            MatomoUtils.track(view: ["MessageView"])
        }
        .task {
            if thread.hasUnseenMessages {
                try? await mailboxManager.toggleRead(threads: [thread])
            }
        }
        .background(scrollViewBackground)
        .navigationTitle(displayNavigationTitle ? thread.formattedSubject : "")
        .navigationBarThreadViewStyle()
        .backButtonDisplayMode(.minimal)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task {
                        await tryOrDisplayError {
                            try await mailboxManager.toggleStar(threads: [thread])
                        }
                    }
                } label: {
                    Image(resource: thread.flagged ? MailResourcesAsset.starFull : MailResourcesAsset.star)
                }
            }
            ToolbarItemGroup(placement: .bottomBar) {
                ForEach(toolbarActions) { action in
                    ToolbarButton(text: action.title, icon: action.icon) {
                        didTap(action: action)
                    }
                    Spacer()
                }
                ToolbarButton(text: MailResourcesStrings.Localizable.buttonMore,
                              icon: MailResourcesAsset.plusActions) {
                    threadBottomSheet.open(state: .actions(.threads([thread.thaw() ?? thread])))
                }
            }
        }
        .environmentObject(mailboxManager)
        .environmentObject(bottomSheet)
        .environmentObject(threadBottomSheet)
        .sheet(item: $messageReply) { messageReply in
            ComposeMessageView.replyOrForwardMessage(messageReply: messageReply, mailboxManager: mailboxManager)
        }
        .sheet(isPresented: $moveSheet.isShowing) {
            if case let .move(handler) = moveSheet.state {
                MoveEmailView.sheetView(mailboxManager: mailboxManager, moveHandler: handler)
            }
        }
        .floatingPanel(state: bottomSheet) {
            switch bottomSheet.state {
            case let .contact(recipient, isRemote):
                ContactActionsView(
                    recipient: recipient,
                    isRemoteContact: isRemote,
                    bottomSheet: bottomSheet,
                    mailboxManager: mailboxManager
                )
            case let .replyOption(message, isThread):
                ReplyActionsView(
                    mailboxManager: mailboxManager,
                    target: isThread ? .threads([thread]) : .message(message),
                    state: threadBottomSheet,
                    globalSheet: globalBottomSheet
                ) { message, replyMode in
                    bottomSheet.close()
                    messageReply = MessageReply(message: message, replyMode: replyMode)
                }
            case .none:
                EmptyView()
            }
        }
        .floatingPanel(state: threadBottomSheet, halfOpening: true) {
            if case let .actions(target) = threadBottomSheet.state, !target.isInvalidated {
                ActionsView(mailboxManager: mailboxManager,
                            target: target,
                            state: threadBottomSheet,
                            globalSheet: globalBottomSheet,
                            moveSheet: moveSheet) { message, replyMode in
                    messageReply = MessageReply(message: message, replyMode: replyMode)
                }
            }
        }
        .onChange(of: messages) { newMessagesList in
            if newMessagesList.isEmpty {
                dismiss()
            }
            if thread.messageInFolderCount == 0 {
                dismiss()
            }
        }
    }

    private var scrollViewBackground: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                MailResourcesAsset.backgroundColor.swiftUiColor
                    .frame(maxHeight: proxy.size.height * 0.2)
                threadBackground
            }
        }
    }

    private func didTap(action: Action) {
        switch action {
        case .reply:
            guard let message = messages.last else { return }

            let from = message.from.where { $0.email != mailboxManager.mailbox.email }
            let cc = message.cc.where { $0.email != mailboxManager.mailbox.email }
            let to = message.to.where { $0.email != mailboxManager.mailbox.email }

            if (from.count + cc.count + to.count) > 1 {
                bottomSheet.open(state: .replyOption(message, isThread: true))
            } else {
                messageReply = MessageReply(message: message, replyMode: .reply)
            }
        case .forward:
            guard let message = messages.last else { return }
            Task {
                let attachments = try await mailboxManager.apiFetcher.attachmentsToForward(
                    mailbox: mailboxManager.mailbox,
                    message: message
                ).attachments
                messageReply = MessageReply(message: message, replyMode: .forward(attachments))
            }
        case .archive:
            Task {
                await tryOrDisplayError {
                    let undoRedoAction = try await mailboxManager.move(threads: [thread], to: .archive)
                    IKSnackBar.showCancelableSnackBar(
                        message: MailResourcesStrings.Localizable.snackbarThreadMoved(FolderRole.archive.localizedName),
                        cancelSuccessMessage: MailResourcesStrings.Localizable.snackbarMoveCancelled,
                        undoRedoAction: undoRedoAction,
                        mailboxManager: mailboxManager
                    )
                    dismiss()
                }
            }
        case .delete:
            Task {
                await tryOrDisplayError {
                    try await mailboxManager.moveOrDelete(threads: [thread])
                    dismiss()
                }
            }
        default:
            break
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
        ThreadView(
            mailboxManager: PreviewHelper.sampleMailboxManager,
            thread: PreviewHelper.sampleThread
        )
    }
}
