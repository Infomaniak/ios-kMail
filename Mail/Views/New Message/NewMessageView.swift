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
    @State var draftBody = "<br><br>Envoyé avec Infomaniak Mail pour iOS" // MailResourcesStrings.newMessagePlaceholderTitle
    @State var showCc: Bool = false

    @Environment(\.presentationMode) var presentationMode

    static var queue = DispatchQueue(label: "com.infomaniak.mail.saveDraft")
    @State var debouncedBufferWrite: DispatchWorkItem?
    let saveExpiration = 3.0

    init(mailboxManager: MailboxManager, draft: Draft? = nil) {
        self.mailboxManager = mailboxManager
        guard let signatureResponse = mailboxManager.getSignatureResponse() else { fatalError() }
        _draft = State(initialValue: draft ?? Draft(identityId: "\(signatureResponse.defaultSignatureId)"))
    }

    var body: some View {
        NavigationView {
            VStack {
                RecipientCellView(
                    text: mailboxManager.mailbox.email,
                    draft: draft,
                    showCcButton: $showCc,
                    type: RecipientCellType.from
                ) { textDidChange() }

                RecipientCellView(draft: draft, showCcButton: $showCc, type: RecipientCellType.to) { textDidChange() }

                if showCc {
                    RecipientCellView(draft: draft, showCcButton: $showCc, type: RecipientCellType.cc) { textDidChange() }
                    RecipientCellView(draft: draft, showCcButton: $showCc, type: RecipientCellType.bcc) { textDidChange() }
                }

                RecipientCellView(draft: draft, showCcButton: $showCc, type: RecipientCellType.object) { textDidChange() }

                RichTextEditor(model: $editor, body: $draftBody) { textDidChange() }
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading:
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "multiply")
                        .tint(Color(MailResourcesAsset.primaryTextColor.color))
                },
                trailing:
                Button(action: {
                    Task {
                        if await send() {
                            DispatchQueue.main.async {
                                self.presentationMode.wrappedValue.dismiss()
                            }
                        } else {
                            // Hanlde message not send - show alert
                        }
                    }
                }) {
                    Image(uiImage: MailResourcesAsset.send.image)
                }
                .tint(Color(MailResourcesAsset.mailPinkColor.color)))
        }
        .navigationViewStyle(.stack)
        .accentColor(.black)
    }

    @MainActor private func send() async -> Bool {
        do {
            return try await mailboxManager.send(draft: draft)
        } catch {
            print("Error while sending email: \(error.localizedDescription)")
            return false
        }
    }

    @MainActor private func saveDraft() async {
        editor.richTextEditor.getHTML { [self] html in
            Task {
                self.draft.body = html!

                do {
                    _ = try await mailboxManager.save(draft: draft)
                } catch {
                    print("Error while saving draft: \(error.localizedDescription)")
                }
            }
        }
    }

    func textDidChange() {
        debouncedBufferWrite?.cancel()
        let debouncedWorkItem = DispatchWorkItem {
            Task {
                await saveDraft()
            }
        }
        NewMessageView.queue.asyncAfter(deadline: .now() + saveExpiration, execute: debouncedWorkItem)
        debouncedBufferWrite = debouncedWorkItem
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
