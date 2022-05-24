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
    @Binding var isPresented: Bool
    @State private var mailboxManager: MailboxManager
    @State private var selectedMailboxItem: Int = 0
    @State var draft: Draft
    @State var editor = RichTextEditorModel()
    @State var showCc = false

    @State private var draftHasChanged = false

    let defaultBody = "<div><br></div><div><br></div><div>Envoyé avec Infomaniak Mail pour iOS<br></div>"

    static var queue = DispatchQueue(label: "com.infomaniak.mail.saveDraft")
    @State var debouncedBufferWrite: DispatchWorkItem?
    let saveExpiration = 3.0

    init(isPresented: Binding<Bool>, mailboxManager: MailboxManager, draft: Draft? = nil) {
        _isPresented = isPresented
        self.mailboxManager = mailboxManager
        self.selectedMailboxItem = AccountManager.instance.mailboxes.firstIndex { $0.mailboxId == mailboxManager.mailbox.mailboxId } ?? 0
        guard let signatureResponse = mailboxManager.getSignatureResponse() else { fatalError() }
        self.draft = draft ?? Draft(messageUid: UUID().uuidString,
                                    body: defaultBody)
        self.draft.identityId = "\(signatureResponse.defaultSignatureId)"
    }

    var body: some View {
        NavigationView {
            VStack {
                HStack(alignment: .firstTextBaseline) {
                    Text(MailResourcesStrings.fromTitle)
                        .textStyle(.bodySecondary)
                    Picker("Mailbox", selection: $selectedMailboxItem) {
                        ForEach(AccountManager.instance.mailboxes.indices, id: \.self) { i in
                            Text(AccountManager.instance.mailboxes[i].email).tag(i)
                        }
                    }
                    .textStyle(.body)
                    Spacer()
                }

                SeparatorView(withPadding: false, fullWidth: true)

                RecipientCellView(draft: $draft, showCcButton: $showCc, type: .to)

                if showCc {
                    RecipientCellView(draft: $draft, showCcButton: $showCc, type: .cc)
                    RecipientCellView(draft: $draft, showCcButton: $showCc, type: .bcc)
                }

                RecipientCellView(draft: $draft, showCcButton: $showCc, type: .object)

                RichTextEditor(model: $editor, body: draft.body) { body in
                    draft.body = body
                    textDidChange()
                }
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading:
                Button {
                    if draftHasChanged {
                        debouncedBufferWrite?.cancel()
                        Task {
                            await saveDraft()
                        }
                    }
                    self.dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .tint(MailResourcesAsset.primaryTextColor)
                },
                trailing:
                Button {
                    Task {
                        await send()
                        // TODO: show confirmation snackbar or handle error
                    }
                    self.dismiss()
                } label: {
                    Image(resource: MailResourcesAsset.send)
                }
                .tint(MailResourcesAsset.mailPinkColor))
        }
        .onChange(of: draft) { _ in
            textDidChange()
        }
        .onChange(of: selectedMailboxItem) { _ in
            let mailbox = AccountManager.instance.mailboxes[selectedMailboxItem]
            guard let mailboxManager = AccountManager.instance.getMailboxManager(for: mailbox),
                  let signatureResponse = mailboxManager.getSignatureResponse() else { return }
            self.mailboxManager = mailboxManager
            draft.identityId = "\(signatureResponse.defaultSignatureId)"
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
        draftHasChanged = true
    private func textDidChange() {
        draftHasChanged = true
        draft.isOffline = true
        debouncedBufferWrite?.cancel()
        let debouncedWorkItem = DispatchWorkItem {
            Task {
                await saveDraft()
            }
        }
        NewMessageView.queue.asyncAfter(deadline: .now() + saveExpiration, execute: debouncedWorkItem)
        debouncedBufferWrite = debouncedWorkItem
    }

    private func dismiss() {
        isPresented = false
    }
}

struct NewMessageView_Previews: PreviewProvider {
    static var previews: some View {
        NewMessageView(
            isPresented: .constant(true),
            mailboxManager: MailboxManager(mailbox: PreviewHelper.sampleMailbox, apiFetcher: MailApiFetcher()),
            draft: Draft()
        )
    }
}
