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

struct MessageView: View {
    @ObservedRealmObject var message: Message
    private var mailboxManager: MailboxManager
    @State var model = WebViewModel()
    @State private var webViewHeight: CGFloat = .zero
    @State var isHeaderReduced = true

    init(mailboxManager: MailboxManager, message: Message) {
        self.mailboxManager = mailboxManager
        self.message = message
    }

    var body: some View {
        VStack {
            MessageHeaderView(message: message, isReduced: $isHeaderReduced)
            GeometryReader { proxy in
                WebView(model: $model, dynamicHeight: $webViewHeight, proxy: proxy)
                    .frame(height: webViewHeight)
                    .background(Color.blue)
            }
            .frame(height: webViewHeight)
            .onAppear {
                model.loadHTMLString(value: message.body?.value)
            }
            .onChange(of: message.body) { _ in
                model.loadHTMLString(value: message.body?.value)
            }
        }
        .padding(8)
        .onAppear {
            if self.message.shouldComplete {
                Task {
                    await fetchMessage()
                }
            }
        }
    }

    @MainActor private func fetchMessage() async {
        do {
            try await mailboxManager.message(message: message)
        } catch {
            print("Error while getting messages: \(error.localizedDescription)")
        }
    }
}

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        MessageView(
            mailboxManager: MailboxManager(mailbox: PreviewHelper.sampleMailbox, apiFetcher: MailApiFetcher()),
            message: PreviewHelper.sampleMessage
        )
    }
}
