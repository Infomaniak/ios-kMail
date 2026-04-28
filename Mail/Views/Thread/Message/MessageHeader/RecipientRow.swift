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
import InfomaniakCoreSwiftUI
import MailCore
import MailCoreUI
import RealmSwift
import SwiftUI

struct RecipientRow: View {
    @Environment(\.currentUser) private var currentUser
    @EnvironmentObject private var mailboxManager: MailboxManager

    let title: String
    let recipients: RealmSwift.List<Recipient>
    var bimi: Bimi?

    var body: some View {
        GridRow {
            Text(title)
                .textStyle(.bodySmallSecondary)

            VStack(alignment: .leading, spacing: 4) {
                ForEach(recipients, id: \.self) { recipient in
                    FlowLayout(alignment: .leading, horizontalSpacing: IKPadding.micro) {
                        ContactActionsMenuView(recipient: recipient, bimi: bimi) {
                            Text(recipient.name.isEmpty ? recipient.email : recipient.name)
                                .textStyle(.bodySmallAccent)
                                .multilineTextAlignment(.leading)
                                .layoutPriority(1)
                        }
                        .environmentObject(mailboxManager)
                        .environment(\.currentUser, currentUser)

                        if !recipient.name.isEmpty && recipient.name != recipient.email {
                            Text(recipient.email)
                                .textStyle(.labelSecondary)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    RecipientRow(title: "To", recipients: PreviewHelper.sampleMessage.to)
}
