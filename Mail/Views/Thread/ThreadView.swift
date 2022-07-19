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

import BottomSheet
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

class MessageBottomSheet: BottomSheetState<MessageBottomSheet.State, MessageBottomSheet.Position> {
    enum State: Equatable {
        case contact(Recipient, isRemote: Bool)
    }

    enum Position: CGFloat, CaseIterable {
        case defaultHeight = 285, remoteContactHeight = 230, hidden = 0
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
    private let bottomSheetOptions = Constants.bottomSheetOptions + [.absolutePositionValue]
    private let threadBottomSheetOptions = Constants.bottomSheetOptions + [.appleScrollBehavior]
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
            let appereance = UIToolbarAppearance()
            appereance.configureWithOpaqueBackground()
            appereance.backgroundColor = MailResourcesAsset.backgroundToolbarColor.color
            appereance.shadowColor = .clear
            UIToolbar.appearance().standardAppearance = appereance
            UIToolbar.appearance().scrollEdgeAppearance = appereance
            navigationController?.toolbar.barTintColor = .white
            navigationController?.toolbar.setShadowImage(UIImage(), forToolbarPosition: .any)
            // Style navigation bar
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = nil
        }
        .environmentObject(mailboxManager)
        .environmentObject(sheet)
        .environmentObject(bottomSheet)
        .environmentObject(threadBottomSheet)
        .task {
            if thread.unseenMessages > 0 {
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
                    Button {
                        didTap(action: action)
                    } label: {
                        Label {
                            Text(action.title)
                                .font(MailTextStyle.caption.font)
                        } icon: {
                            Image(resource: action.icon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 22)
                        }
                        .dynamicLabelStyle(sizeClass: sizeClass ?? .regular)
                    }
                    Spacer()
                }
                Button {
                    threadBottomSheet.open(state: .actions(.thread(thread.thaw() ?? thread)), position: .middle)
                } label: {
                    Label {
                        Text(MailResourcesStrings.Localizable.buttonMore)
                            .font(MailTextStyle.caption.font)
                    } icon: {
                        Image(resource: MailResourcesAsset.plusActions)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                    }
                    .dynamicLabelStyle(sizeClass: sizeClass ?? .regular)
                }
            }
        }
        .sheet(isPresented: $sheet.isShowing) {
            switch sheet.state {
            case let .attachment(attachment):
                AttachmentPreview(isPresented: $sheet.isShowing, attachment: attachment)
            case let .reply(message, replyMode):
                NewMessageView(isPresented: $sheet.isShowing, mailboxManager: mailboxManager, draft: .replying(to: message, mode: replyMode))
            case let .edit(draft):
                NewMessageView(isPresented: $sheet.isShowing, mailboxManager: mailboxManager, draft: draft.asUnmanaged())
            case let .write(recipient):
                NewMessageView(isPresented: $sheet.isShowing, mailboxManager: mailboxManager, draft: .writing(to: recipient))
            case .none:
                EmptyView()
            }
        }
        .bottomSheet(bottomSheetPosition: $bottomSheet.position, options: bottomSheetOptions) {
            switch bottomSheet.state {
            case let .contact(recipient, isRemote):
                ContactActionsView(recipient: recipient, isRemoteContact: isRemote, bottomSheet: bottomSheet, sheet: sheet)
            case .none:
                EmptyView()
            }
        }
        .bottomSheet(bottomSheetPosition: $threadBottomSheet.position, options: threadBottomSheetOptions) {
            switch threadBottomSheet.state {
            case let .actions(target):
                if target.isInvalidated {
                    EmptyView()
                } else {
                    ActionsView(mailboxManager: mailboxManager,
                                target: target,
                                state: threadBottomSheet,
                                globalSheet: globalBottomSheet) { message, replyMode in
                        sheet.state = .reply(message, replyMode)
                    }
                }
            case .none:
                EmptyView()
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
            sheet.state = .reply(message, .reply)
        case .forward:
            guard let message = messages.last else { return }
            sheet.state = .reply(message, .forward)
        case .archive:
            Task {
                await tryOrDisplayError {
                    let response = try await mailboxManager.move(thread: thread, to: .archive)
                    IKSnackBar.showCancelableSnackBar(message: MailResourcesStrings.Localizable.snackbarThreadMoved(FolderRole.archive.localizedName),
                                                      cancelSuccessMessage: MailResourcesStrings.Localizable.snackbarMoveCancelled,
                                                      cancelableResponse: response,
                                                      mailboxManager: mailboxManager)
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
