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
import SwiftUI

struct SettingsNotificationsView: View {
    @AppStorage(UserDefaults.shared.key(.notificationsEnabled), store: .shared) private var notifications = DefaultPreferences
        .notificationsEnabled

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Toggle(isOn: Binding(get: {
                    notifications
                }, set: { newValue in
                    notifications = newValue
                })) {
                    Text(MailResourcesStrings.Localizable.settingsEnableNotifications)
                        .textStyle(.body)
                }

                IKDivider()

                ForEach(AccountManager.instance.mailboxes, id: \.id) { mailbox in
                    Toggle(isOn: Binding(get: {
                        notifications && UserDefaults.shared.bool(forKey: mailbox.objectId)
                    }, set: { newValue in
                        UserDefaults.shared.set(newValue, forKey: mailbox.objectId)
                    })) {
                        Text(mailbox.email)
                            .textStyle(.body)
                    }
                    .disabled(!notifications)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
        }
        .background(MailResourcesAsset.backgroundColor.swiftUiColor)
        .navigationBarTitle(MailResourcesStrings.Localizable.settingsMailboxGeneralNotifications, displayMode: .inline)
    }
}

struct SettingsNotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsNotificationsView()
    }
}
