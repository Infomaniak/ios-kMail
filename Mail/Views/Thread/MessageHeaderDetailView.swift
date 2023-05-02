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

import InfomaniakCore
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailResources
import RealmSwift
import SwiftUI
import WrappingHStack

struct ViewWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct ViewGeometry: View {
    var body: some View {
        GeometryReader { geometry in
            Color.clear
                .preference(key: ViewWidthKey.self, value: geometry.size.width)
        }
    }
}

struct MessageHeaderDetailView: View {
    @ObservedRealmObject var message: Message

    @State private var labelWidth: CGFloat = 100

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RecipientLabel(
                labelWidth: $labelWidth,
                title: MailResourcesStrings.Localizable.fromTitle,
                recipients: message.from
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
                MailResourcesAsset.calendar.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: labelWidth, height: 17, alignment: .leading)
                    .foregroundColor(MailResourcesAsset.textSecondaryColor)
                Text(message.date.formatted(date: .long, time: .shortened))
                    .textStyle(.bodySmallSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onPreferenceChange(ViewWidthKey.self) {
            labelWidth = $0
        }
    }
}

struct MessageHeaderDetailView_Previews: PreviewProvider {
    static var previews: some View {
        MessageHeaderDetailView(message: PreviewHelper.sampleMessage)
    }
}

struct RecipientLabel: View {
    @Binding var labelWidth: CGFloat
    let title: String
    let recipients: RealmSwift.List<Recipient>

    @State private var contactViewRecipient: Recipient?

    @LazyInjectService private var matomo: MatomoUtils

    var body: some View {
        HStack(alignment: .top) {
            Text(title)
                .textStyle(.bodySmallSecondary)
                .background(ViewGeometry())
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
                        .adaptivePanel(item: $contactViewRecipient) { recipient in
                            ContactActionsView(recipient: recipient)
                        }

                        if !recipient.name.isEmpty {
                            Text(recipient.email)
                                .textStyle(.labelSecondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
        .padding(.bottom, 2)
    }
}
