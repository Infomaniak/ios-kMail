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

import MailCore
import MailResources
import RealmSwift
import SwiftUI

// TODO: Rename without V2

enum ComposeViewFieldType: Hashable {
    case from, to, cc, bcc, subject, editor
    case chip(Int, Recipient)

    var title: String {
        switch self {
        case .from:
            return MailResourcesStrings.Localizable.fromTitle
        case .to:
            return MailResourcesStrings.Localizable.toTitle
        case .cc:
            return MailResourcesStrings.Localizable.ccTitle
        case .bcc:
            return MailResourcesStrings.Localizable.bccTitle
        case .subject:
            return MailResourcesStrings.Localizable.subjectTitle
        case .editor:
            return "editor"
        case .chip:
            return "Recipient Chip"
        }
    }
}

final class NewMessageAlert: SheetState<NewMessageAlert.State> {
    enum State {
        case link(handler: (String) -> Void)
        case emptySubject(handler: () -> Void)
    }
}

struct ComposeMessageViewV2: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var mailboxManager: MailboxManager
    @StateObject private var attachmentsManager: AttachmentsManager
    @StateObject private var alert = NewMessageAlert()

    @StateRealmObject private var draft: Draft

    let messageReply: MessageReply?

    private var isSendButtonDisabled: Bool {
        return draft.identityId?.isEmpty == true || draft.recipientsAreEmpty || !attachmentsManager.allAttachmentsUploaded
    }

    init(draft: Draft, mailboxManager: MailboxManager, messageReply: MessageReply? = nil) {
        self.messageReply = messageReply

        Self.saveNewDraftInRealm(mailboxManager.getRealm(), draft: draft)
        _draft = StateRealmObject(wrappedValue: draft)

        _mailboxManager = StateObject(wrappedValue: mailboxManager)
        _attachmentsManager = StateObject(wrappedValue: AttachmentsManager(draft: draft, mailboxManager: mailboxManager))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    ComposeMessageHeaderViewV2(draft: draft)

                    ComposeMessageBodyViewV2(
                        attachmentsManager: attachmentsManager,
                        alert: alert,
                        draft: draft,
                        messageReply: messageReply
                    )
                }
            }
            .background(MailResourcesAsset.backgroundColor.swiftUIColor)
            .navigationTitle(MailResourcesStrings.Localizable.buttonNewMessage)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: dismissDraft) {
                        Label(MailResourcesStrings.Localizable.buttonClose, systemImage: "xmark")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: sendDraft) {
                        Label(MailResourcesStrings.Localizable.send, image: MailResourcesAsset.send.name)
                            .disabled(isSendButtonDisabled)
                    }
                }
            }
        }
        .matomoView(view: ["ComposeMessage"])
    }

    private func dismissDraft() {
        // TODO: Check attachments
        dismiss()
    }

    private func sendDraft() {
        // TODO: Check attachments
        dismiss()
    }

    private static func saveNewDraftInRealm(_ realm: Realm, draft: Draft) {
        try? realm.write {
            draft.action = draft.action == nil && draft.remoteUUID.isEmpty ? .initialSave : .save
            draft.delay = UserDefaults.shared.cancelSendDelay.rawValue

            realm.add(draft, update: .modified)
        }
    }
}

struct ComposeMessageViewV2_Previews: PreviewProvider {
    static var previews: some View {
        ComposeMessageViewV2.newMessage(mailboxManager: PreviewHelper.sampleMailboxManager)
    }
}
