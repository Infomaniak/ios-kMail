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
import Introspect
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

class MessageSheet: SheetState<MessageSheet.State> {
    enum State: Equatable {
        case attachment(Attachment)
        case reply(Message, ReplyMode)
        case edit(Draft)
        case write(to: Recipient)
    }
}

class MessageBottomSheet: DisplayedFloatingPanelState<MessageBottomSheet.State> {
    enum State: Equatable {
        case contact(Recipient, isRemote: Bool)
        case replyOption(Message, isThread: Bool)
    }
}

struct ThreadView: View {
    @ObservedRealmObject var thread: Thread
    private var mailboxManager: MailboxManager
    private var navigationController: UINavigationController?
    private var folderId: String?

    @State private var displayNavigationTitle = false
    @StateObject private var sheet = MessageSheet()
    @StateObject private var bottomSheet = MessageBottomSheet()
    @StateObject private var threadBottomSheet = ThreadBottomSheet()

    @EnvironmentObject var globalBottomSheet: GlobalBottomSheet
    @Environment(\.verticalSizeClass) var sizeClass
    @Environment(\.dismiss) var dismiss

    private let trashId: String
    private let toolbarActions: [Action] = [.reply, .forward, .archive, .delete]

    private var isTrashFolder: Bool {
        return thread.parent?._id == trashId
    }

    private var messages: [Message] {
        return Array(thread.messages)
            .filter { $0.isDuplicate != true && (isTrashFolder || $0.folderId != trashId) }
            .sorted { $0.date.compare($1.date) == .orderedAscending }
    }

    init(mailboxManager: MailboxManager, thread: Thread, folderId: String?, navigationController: UINavigationController?) {
        self.mailboxManager = mailboxManager
        self.thread = thread
        self.folderId = folderId
        self.navigationController = navigationController
        trashId = mailboxManager.getFolder(with: .trash)?._id ?? ""
    }

    var body: some View {
        ScrollView {
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
                .padding(.top, 8)
                .padding(.horizontal, 16)

            LazyVStack(spacing: 0) {
                ForEach(messages.indices, id: \.self) { index in
                    let isMessageExpanded = ((index == messages.count - 1) && !messages[index].isDraft) || !messages[index].seen
                    MessageView(message: messages[index], isMessageExpanded: isMessageExpanded)
                    if index < messages.count - 1 {
                        IKDivider()
                            .padding(.horizontal, 8)
                    }
                }
            }
        }
        .background(MailResourcesAsset.backgroundColor.swiftUiColor)
        .coordinateSpace(name: "scrollView")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
            displayNavigationTitle = offset.y < -85
        }
        .navigationTitle(displayNavigationTitle ? thread.formattedSubject : "")
        .backButtonDisplayMode(.minimal)
        .onAppear {
            MatomoUtils.track(view: ["MessageView"])
            // Style toolbar
            let toolbarAppearance = UIToolbarAppearance()
            toolbarAppearance.configureWithOpaqueBackground()
            toolbarAppearance.backgroundColor = MailResourcesAsset.backgroundToolbarColor.color
            toolbarAppearance.shadowColor = .clear
            UIToolbar.appearance().standardAppearance = toolbarAppearance
            UIToolbar.appearance().scrollEdgeAppearance = toolbarAppearance
            navigationController?.toolbar.barTintColor = .white
            navigationController?.toolbar.setShadowImage(UIImage(), forToolbarPosition: .any)
            // Style navigation bar
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithDefaultBackground()
            navigationController?.navigationBar.standardAppearance = navBarAppearance
            navigationController?.navigationBar.scrollEdgeAppearance = nil
        }
        .environmentObject(mailboxManager)
        .environmentObject(sheet)
        .environmentObject(bottomSheet)
        .environmentObject(threadBottomSheet)
        .task {
            if thread.hasUnseenMessages {
                try? await mailboxManager.toggleRead(thread: thread)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task {
                        await tryOrDisplayError {
                            try await mailboxManager.toggleStar(thread: thread)
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
                    threadBottomSheet.open(state: .actions(.thread(thread.thaw() ?? thread)))
                }
            }
        }
        .sheet(isPresented: $sheet.isShowing) {
            switch sheet.state {
            case let .attachment(attachment):
                AttachmentPreview(isPresented: $sheet.isShowing, attachment: attachment)
            case let .reply(message, replyMode):
                NewMessageView(mailboxManager: mailboxManager, draft: .replying(to: message, mode: replyMode))
            case let .edit(draft):
                NewMessageView(mailboxManager: mailboxManager, draft: draft.asUnmanaged())
            case let .write(recipient):
                NewMessageView(mailboxManager: mailboxManager, draft: .writing(to: recipient))
            case .none:
                EmptyView()
            }
        }
        .floatingPanel(state: bottomSheet) {
            switch bottomSheet.state {
            case let .contact(recipient, isRemote):
                ContactActionsView(recipient: recipient, isRemoteContact: isRemote, bottomSheet: bottomSheet, sheet: sheet)
            case let .replyOption(message, isThread):
                ReplyActionsView(
                    mailboxManager: mailboxManager,
                    target: isThread ? .thread(thread) : .message(message),
                    state: threadBottomSheet,
                    globalSheet: globalBottomSheet
                ) { message, replyMode in
                    bottomSheet.close()
                    sheet.state = .reply(message, replyMode)
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
                            globalSheet: globalBottomSheet) { message, replyMode in
                    sheet.state = .reply(message, replyMode)
                }
            }
        }
        .onChange(of: messages) { newMessagesList in
            if let folderId = folderId, newMessagesList.filter({ $0.folderId == folderId }).isEmpty {
                dismiss()
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
                sheet.state = .reply(message, .reply)
            }
        case .forward:
            guard let message = messages.last else { return }
            Task {
                let attachments = try await mailboxManager.apiFetcher.attachmentsToForward(
                    mailbox: mailboxManager.mailbox,
                    message: message
                ).attachments
                sheet.state = .reply(message, .forward(attachments))
            }
        case .archive:
            Task {
                await tryOrDisplayError {
                    let undoRedoAction = try await mailboxManager.move(thread: thread, to: .archive)
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
                    try await mailboxManager.moveOrDelete(thread: thread)
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
            thread: PreviewHelper.sampleThread,
            folderId: nil,
            navigationController: nil
        )
    }
}
