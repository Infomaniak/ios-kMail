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
import RealmSwift
import SwiftUI

struct NewMessageView: View {
    private var mailboxManager: MailboxManager
    @ObservedRealmObject var draft: Draft

    @State var editor = RichTextEditorModel()
    @State var draftBody = "Rédigez votre message"

    @Environment(\.presentationMode) var presentationMode

    init(mailboxManager: MailboxManager, draft: Draft) {
        self.mailboxManager = mailboxManager
        self.draft = draft
    }

    var body: some View {
        NavigationView {
            VStack {
                RecipientCellView(from: mailboxManager.mailbox.email, draft: draft, text: "De : ")
                RecipientCellView(draft: draft, text: "À :")
                RecipientCellView(draft: draft, text: "Objet :")

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
                })
        }
        .accentColor(.black)
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
