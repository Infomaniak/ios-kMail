/*
 Infomaniak Mail - iOS App
 Copyright (C) 2025 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import MailCore
import MailCoreUI
import MailResources
import RealmSwift
import SwiftUI

struct MessageEuriaBannersView: View {
    @EnvironmentObject private var mailboxManager: MailboxManager

    @ObservedRealmObject var message: Message

    var body: some View {
        if let state = message.summaryState {
            MessageEuriaContentView(title: state.title, isError: message.summaryState == .error) {
                if let summary = message.summary {
                    Text(summary)
                        .textStyle(.bodySmall)
                } else if message.summaryState == .error {
                    Button {
                        Task {
                            try await mailboxManager.summarize(message: message)
                        }
                    } label: {
                        Text(MailResourcesStrings.Localizable.aiButtonRetry)
                            .font(MailTextStyle.body.font)
                            .foregroundStyle(MailResourcesAsset.primaryBlueColor.swiftUIColor)
                    }
                    .padding(.leading, 22)
                }
            } dismiss: {
                guard let liveMessage = message.thaw() else { return }
                try? liveMessage.realm?.write {
                    liveMessage.summaryState = nil
                }
            }
        }
    }
}

#Preview {
    MessageEuriaBannersView(message: PreviewHelper.sampleMessage)
}
