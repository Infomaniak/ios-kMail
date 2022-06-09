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
import MailCore
import MailResources
import RealmSwift
import SwiftUI

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

    @StateObject private var sheet = MessageSheet()
    @StateObject private var bottomSheet = MessageBottomSheet()
    @StateObject private var threadBottomSheet = ThreadBottomSheet()

    private let trashId: String
    private let bottomSheetOptions = Constants.bottomSheetOptions + [.absolutePositionValue]
    private let threadBottomSheetOptions = Constants.bottomSheetOptions + [.appleScrollBehavior]

    private var isTrashFolder: Bool {
        return thread.parent?._id == trashId
    }

    private var messages: [Message] {
        return Array(thread.messages
            .where { $0.isDuplicate != true }
            .sorted(by: \.date, ascending: true))
            .filter { isTrashFolder || $0.folderId != trashId }
    }

    init(mailboxManager: MailboxManager, thread: Thread) {
        self.mailboxManager = mailboxManager
        self.thread = thread
        trashId = mailboxManager.getFolder(with: .trash)?._id ?? ""
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(messages.indices, id: \.self) { index in
                        let isMessageExpanded = ((index == messages.count - 1) && !messages[index].isDraft) || !messages[index].seen
                        MessageView(message: messages[index], isMessageExpanded: isMessageExpanded, showActionButtons: messages.count > 1)
                        if index < messages.count - 1 {
                            MessageSeparatorView()
                        }
                    }
                }
            }
            .navigationTitle(thread.formattedSubject)
            .backButtonDisplayMode(.minimal)
            .onAppear {
                MatomoUtils.track(view: ["MessageView"])
                // Style toolbar
                let appereance = UIToolbarAppearance()
                appereance.configureWithOpaqueBackground()
                appereance.backgroundColor = MailResourcesAsset.backgroundSearchBar.color
                UIToolbar.appearance().standardAppearance = appereance
            }
        }
        .environmentObject(mailboxManager)
        .environmentObject(sheet)
        .environmentObject(bottomSheet)
        .environmentObject(threadBottomSheet)
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Group {
                    Button {
                        guard let message = messages.last else { return }
                        sheet.state = .reply(message, .reply)
                    } label: {
                        VStack(spacing: 0) {
                            Image(resource: MailResourcesAsset.emailActionReply)
                            Text(MailResourcesStrings.buttonReply)
                        }
                    }
                    Spacer()
                    Button {
                        guard let message = messages.last else { return }
                        sheet.state = .reply(message, .forward)
                    } label: {
                        VStack(spacing: 0) {
                            Image(resource: MailResourcesAsset.emailActionTransfer)
                            Text(MailResourcesStrings.buttonForward)
                        }
                    }
                    Spacer()
                    Button {
                        threadBottomSheet.open(state: .actions(.thread(thread)), position: .middle)
                    } label: {
                        VStack(spacing: 0) {
                            Image(systemName: "ellipsis")
                                .frame(width: 24, height: 24)
                            Text(MailResourcesStrings.buttonMore)
                        }
                    }
                }
                .textStyle(.calloutHighlighted)
            }
        }
        .sheet(isPresented: $sheet.isShowing) {
            switch sheet.state {
            case let .attachment(attachment):
                AttachmentPreview(isPresented: $sheet.isShowing, attachment: attachment)
            case let .reply(message, replyMode):
                NewMessageView(isPresented: $sheet.isShowing, mailboxManager: mailboxManager, draft: Draft.replying(to: message, mode: replyMode))
            case let .edit(draft):
                NewMessageView(isPresented: $sheet.isShowing, mailboxManager: mailboxManager, draft: draft)
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
                ActionsView(target: target)
            case .none:
                EmptyView()
            }
        }
    }
}

struct ThreadView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadView(
            mailboxManager: MailboxManager(mailbox: PreviewHelper.sampleMailbox, apiFetcher: MailApiFetcher()),
            thread: PreviewHelper.sampleThread
        )
    }
}
