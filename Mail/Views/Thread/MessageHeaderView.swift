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

struct MessageHeaderView: View {
    @StateRealmObject var message: Message
    @Binding var isReduced: Bool

    var body: some View {
        HStack(alignment: .top) {
            if let recipient = message.from.first {
                RecipientImage(recipient: recipient)
            }

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .firstTextBaseline) {
                        ForEach(message.from, id: \.email) { recipient in
                            Text(recipient.title)
                                .font(.system(size: 16))
                                .fontWeight(.medium)
                        }
                        Text(Constants.formatDate(message.date))
                            .font(.system(size: 13))
                            .fontWeight(.regular)
                            .foregroundColor(Color(MailResourcesAsset.secondaryTextColor.color))
                        Spacer()
                        Image(systemName: isReduced ? "chevron.down" : "chevron.up")
                            .frame(width: 12)
                            .onTapGesture {
                                isReduced.toggle()
                            }
                    }

                    if isReduced {
                        Text(ListFormatter.localizedString(byJoining: message.recipients.map(\.title)))
                            .lineLimit(1)
                            .font(.system(size: 14))
                            .foregroundColor(Color(MailResourcesAsset.secondaryTextColor.color))
                    } else {
                        Text(message.from.first?.email ?? "")
                            .foregroundColor(Color(MailResourcesAsset.primaryTextColor.color))
                            .font(.system(size: 14))
                            .fontWeight(.regular)

                        VStack(alignment: .leading) {
                            ForEach(Array(message.recipients.enumerated()), id: \.offset) { index, recipient in
                                HStack(alignment: .firstTextBaseline, spacing: 2) {
                                    if index == 0 {
                                        Text("À:")
                                    }
                                    Text(recipient.name)
                                        .foregroundColor(Color(MailResourcesAsset.primaryTextColor.color))
                                    Text("(\(recipient.email))")
                                        .font(.system(size: 13))
                                    if index < message.recipients.count - 1 {
                                        Text(",")
                                    }
                                    Spacer()
                                }
                                .foregroundColor(Color(MailResourcesAsset.secondaryTextColor.color))
                                .font(.system(size: 14))
                            }
                        }
                        .padding(.top, 6)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MessageHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MessageHeaderView(message: PreviewHelper.sampleMessage, isReduced: .constant(true))
            MessageHeaderView(message: PreviewHelper.sampleMessage, isReduced: .constant(false))
        }
    }
}
