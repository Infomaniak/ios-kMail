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

struct NewMessageView: View {
    private var mailboxManager: MailboxManager
    @State var draft: Draft
    @State var editor = RichTextEditorModel()
    @State var draftBody = MailResourcesStrings.newMessagePlaceholderTitle
    @State private var unfoldDetails = false

    @Environment(\.presentationMode) var presentationMode

    init(mailboxManager: MailboxManager, draft: Draft? = nil) {
        self.mailboxManager = mailboxManager
        guard let signatureResponse = mailboxManager.getSignatureResponse() else { fatalError() }
        _draft = State(initialValue: draft ?? Draft(identityId: "\(signatureResponse.defaultSignatureId)"))
    }

    var body: some View {
        NavigationView {
            VStack {
                RecipientCellView(from: mailboxManager.mailbox.email, draft: draft, type: RecipientCellType.from)

                DisclosureGroup(isExpanded: $unfoldDetails) {
                    VStack {
                        RecipientCellView(draft: draft, type: RecipientCellType.cc)
                        RecipientCellView(draft: draft, type: RecipientCellType.bcc)
                    }
                    .padding(.top, 5)
                } label: {
                    RecipientCellView(draft: draft, type: RecipientCellType.to)
                }
                RecipientCellView(draft: draft, type: RecipientCellType.object)

                RichTextEditor(model: $editor, body: $draftBody)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading:
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "multiply")
                    }
                },
                trailing: HStack {
                    Button("Send") {
                        Task {
                            await send()
                            DispatchQueue.main.async {
                                self.presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }
                    Button("Save") {
                        Task {
                            await saveDraft()
                            DispatchQueue.main.async {}
                        }
                    }
                })
        }
        .navigationViewStyle(.stack)
        .accentColor(.black)
    }

    @MainActor private func send() async {
        draft.action = .send

        do {
            try await mailboxManager.send(draft: draft)
        } catch {
            print("Error while sending email: \(error.localizedDescription)")
        }
    }

    @MainActor private func saveDraft() async {
        editor.richTextEditor.getHTML { [self] html in
            Task {
                self.draft.body = html!

                draft.action = .save

                do {
                    let saveResponse = try await mailboxManager.save(draft: draft)
                    draft.uuid = saveResponse.uuid
                } catch {
                    print("Error while saving draft: \(error.localizedDescription)")
                }
            }
        }
    }
}

struct NewMessageView_Previews: PreviewProvider {
    static var previews: some View {
        NewMessageView(
            mailboxManager: MailboxManager(mailbox: PreviewHelper.sampleMailbox, apiFetcher: MailApiFetcher()),
            draft: Draft()
        )
    }
}
