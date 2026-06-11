/*
 Infomaniak Mail - iOS App
 Copyright (C) 2026 Infomaniak Network SA

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
import MailResources
import RealmSwift
import SwiftUI

struct ComposeMessageContactList: View {
    @EnvironmentObject private var mailboxManager: MailboxManager
    @Environment(\.currentUser) private var currentUser

    let mentionQuery: String
    let mentionSuggestions: [Recipient]
    let onMentionSelected: (Recipient) -> Void

    @AppStorage(UserDefaults.shared.key(.threadDensity)) private var threadDensity = DefaultPreferences.threadDensity
    var body: some View {
        List {
            Section {
                ForEach(mentionSuggestions) { recipient in
                    RecipientCell(
                        recipient: recipient,
                        highlight: mentionQuery,
                        contextUser: currentUser.value,
                        contextMailboxManager: mailboxManager
                    )
                    .onTapGesture {
                        withAnimation {
                            onMentionSelected(recipient)
                        }
                    }
                }
                .padding(.vertical, threadDensity.cellVerticalPadding)
                .padding(.leading, IKPadding.mini + UnreadIndicatorView.size + IKPadding.mini)
                .padding(.trailing, value: .medium)
            }
            .listRowInsets(.init())
            .listRowSeparator(.hidden)
            .listRowBackground(MailResourcesAsset.backgroundColor.swiftUIColor)
        }
        .scrollIndicators(.hidden)
        .listStyle(.plain)
        .frame(maxHeight: 200)
        .clipShape(
            .rect(topLeadingRadius: 8, topTrailingRadius: 8)
        )
        .shadow(color: MailResourcesAsset.backgroundBlueNavBarColor.swiftUIColor, radius: 10)
    }
}

#Preview {
    ComposeMessageContactList(mentionQuery: "", mentionSuggestions: [], onMentionSelected: { _ in })
}
