/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

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
import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import RealmSwift
import SwiftUI
import WrappingHStack

struct MessageHeaderDetailView: View {
    @ObservedRealmObject var message: Message

    @State private var labelWidth: CGFloat = 100

    var body: some View {
        VStack(alignment: .leading, spacing: IKPadding.mini) {
            RecipientLabel(
                labelWidth: $labelWidth,
                title: MailResourcesStrings.Localizable.fromTitle,
                recipients: message.from,
                bimi: message.bimi
            )
            RecipientLabel(
                labelWidth: $labelWidth,
                title: MailResourcesStrings.Localizable.toTitle,
                recipients: message.to
            )
            if !message.cc.isEmpty {
                RecipientLabel(
                    labelWidth: $labelWidth,
                    title: MailResourcesStrings.Localizable.ccTitle,
                    recipients: message.cc
                )
            }
            if !message.bcc.isEmpty {
                RecipientLabel(
                    labelWidth: $labelWidth,
                    title: MailResourcesStrings.Localizable.bccTitle,
                    recipients: message.bcc
                )
            }
            HStack {
                MailResourcesAsset.calendar
                    .iconSize(.medium)
                Text(message.date.formatted(date: .long, time: .shortened))
            }
            .textStyle(.bodySmallSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onPreferenceChange(ViewWidthKey.self) {
            labelWidth = $0
        }
    }
}

#Preview {
    MessageHeaderDetailView(message: PreviewHelper.sampleMessage)
}

struct RecipientLabel: View {
    @Environment(\.currentUser) private var currentUser
    @EnvironmentObject private var mailboxManager: MailboxManager

    @Binding var labelWidth: CGFloat
    let title: String
    let recipients: RealmSwift.List<Recipient>
    var bimi: Bimi?

    @State private var contactViewRecipient: Recipient?

    @LazyInjectService private var matomo: MatomoUtils

    var body: some View {
        HStack(alignment: .top) {
            Text(title)
                .textStyle(.bodySmallSecondary)
                .background(ViewGeometry(key: ViewWidthKey.self, property: \.size.width))
                .frame(width: labelWidth, alignment: .leading)
            VStack(alignment: .leading, spacing: 4) {
                ForEach(recipients, id: \.self) { recipient in
                    WrappingHStack(lineSpacing: 2) {
                        Button {
                            matomo.track(eventWithCategory: .message, name: "selectRecipient")
                            contactViewRecipient = recipient
                        } label: {
                            Text(recipient.name.isEmpty ? recipient.email : recipient.name)
                                .textStyle(.bodySmallAccent)
                                .lineLimit(1)
                                .layoutPriority(1)
                        }

                        if !recipient.name.isEmpty {
                            Text(recipient.email)
                                .textStyle(.labelSecondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .adaptivePanel(item: $contactViewRecipient) { recipient in
                ContactActionsView(recipient: recipient, bimi: bimi)
                    .environmentObject(mailboxManager)
                    .environment(\.currentUser, currentUser)
                // We need to manually pass environment and environmentObject because of a bug with SwiftUI end popovers on macOS
            }
        }
        .padding(.bottom, 2)
    }
}
