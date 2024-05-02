/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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
import SwiftUI

struct ContactActionsHeaderView: View {
    @EnvironmentObject private var mailboxManager: MailboxManager

    let displayablePerson: CommonContact

    public init(displayablePerson: CommonContact) {
        self.displayablePerson = displayablePerson
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: UIPadding.medium) {
            HStack {
                AvatarView(mailboxManager: mailboxManager, contactConfiguration: .contact(contact: displayablePerson), size: 40)
                    .accessibilityHidden(true)
                VStack(alignment: .leading) {
                    HStack {
                        Text(displayablePerson, format: .displayablePerson())
                            .textStyle(.bodyMedium)
                        IKIcon(MailResourcesAsset.checkmarkAuthentication)
                    }
                    Text(displayablePerson.email)
                        .textStyle(.bodySecondary)
                }
            }
            HStack {
                IKIcon(MailResourcesAsset.checkmarkAuthentication)
                Text(MailResourcesStrings.Localizable.expeditorAuthenticationDescription)
                    .textStyle(.label)
            }
        }
        .accessibilityElement(children: .combine)
        .padding(.horizontal, value: .regular)
    }
}
