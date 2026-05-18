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

import DesignSystem
import MailCore
import MailCoreUI
import MailResources
import RealmSwift
import SwiftUI

struct MessageEuriaBannersView: View {
    @EnvironmentObject private var mailboxManager: MailboxManager

    @ObservedRealmObject var message: Message

    private let summaryNotificationPublisher = NotificationCenter.default.publisher(for: Notification.Name.summaryNotification)
    @State private var summaryState: MessageSummaryState?

    var body: some View {
        Group {
            if let summaryState {
                MessageEuriaContentView(
                    title: summaryState.title(contentLoaded: message.summary != nil),
                    isError: summaryState == .showError
                ) {
                    if let summary = message.summary {
                        Text(summary)
                            .textStyle(.bodySmall)
                    } else if summaryState == .showError {
                        Button {
                            Task {
                                try await mailboxManager.summarize(message: message.freezeIfNeeded())
                            }
                        } label: {
                            Text(MailResourcesStrings.Localizable.aiButtonRetry)
                                .font(MailTextStyle.body.font)
                                .foregroundStyle(MailResourcesAsset.primaryBlueColor.swiftUIColor)
                        }
                        .padding(.leading, value: .large)
                    }
                } dismiss: {
                    self.summaryState = nil
                }
            }
        }
        .padding(.horizontal, value: .medium)
        .onReceive(summaryNotificationPublisher) { notification in
            if let newState = notification.object as? MessageSummaryState {
                summaryState = newState
            }
        }
    }
}

#Preview {
    MessageEuriaBannersView(message: PreviewHelper.sampleMessage)
}
