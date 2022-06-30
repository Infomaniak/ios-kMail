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

    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {}
}

class MessageSheet: SheetState<MessageSheet.State> {
    enum State: Equatable {
        case attachment(Attachment)
        case reply(Message, ReplyMode)
        case edit(Draft)
    }
}

class MessageBottomSheet: BottomSheetState<MessageBottomSheet.State, MessageBottomSheet.Position> {
    enum State: Equatable {
        case contact(Recipient)
    }

    enum Position: CGFloat, CaseIterable {
        case top = 285, hidden = 0
    }
}

struct ThreadView: View {
    @ObservedRealmObject var thread: Thread
    private var mailboxManager: MailboxManager
    private var navigationController: UINavigationController?

    @State private var scrollOffset: CGPoint = .zero
    @StateObject private var sheet = MessageSheet()
    @StateObject private var bottomSheet = MessageBottomSheet()
    @StateObject private var threadBottomSheet = ThreadBottomSheet()

    @EnvironmentObject var globalBottomSheet: GlobalBottomSheet
    @Environment(\.verticalSizeClass) var sizeClass

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

    private var displayNavigationTitle: Bool {
        return scrollOffset.y < -85
    }

    init(mailboxManager: MailboxManager, thread: Thread, navigationController: UINavigationController?) {
        self.mailboxManager = mailboxManager
        self.thread = thread
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
                .padding(.top, 32)
                .padding([.leading, .trailing], 16)

            VStack(spacing: 0) {
                ForEach(messages.indices, id: \.self) { index in
                    let isMessageExpanded = ((index == messages.count - 1) && !messages[index].isDraft) || !messages[index].seen
                    MessageView(message: messages[index], isMessageExpanded: isMessageExpanded)
                    if index < messages.count - 1 {
                        MessageSeparatorView()
                    }
                }
            }
        }
        .coordinateSpace(name: "scrollView")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
            scrollOffset = offset
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
                                .frame(width: 24, height: 24)
                        }
                        .dynamicLabelStyle(sizeClass: sizeClass!)
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
                        Image(systemName: "ellipsis")
                            .frame(width: 24, height: 24)
                    }
                    .dynamicLabelStyle(sizeClass: sizeClass!)
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
            case .none:
                EmptyView()
            }
        }
        .bottomSheet(bottomSheetPosition: $bottomSheet.position, options: bottomSheetOptions) {
            switch bottomSheet.state {
            case let .contact(recipient):
                ContactView(recipient: recipient, bottomSheet: bottomSheet)
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
                }
            }
        case .delete:
            Task {
                await tryOrDisplayError {
                    try await mailboxManager.moveOrDelete(thread: thread)
                }
            }
        default:
            break
        }
    }
}

struct VerticalLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: 8) {
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
            navigationController: nil
        )
    }
}
