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
import InfomaniakDI
import InfomaniakNotifications
import MailCore
import MailResources
import SwiftUI

struct SettingsNotificationsView: View {
    @LazyInjectService private var notificationService: InfomaniakNotifications
    @LazyInjectService private var matomo: MatomoUtils

    @AppStorage(UserDefaults.shared.key(.notificationsEnabled)) private var notificationsEnabled = DefaultPreferences
        .notificationsEnabled
    @State var subscribedTopics: [String]?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Toggle(isOn: $notificationsEnabled) {
                    Text(MailResourcesStrings.Localizable.settingsEnableNotifications)
                        .textStyle(.body)
                }
                .onChange(of: notificationsEnabled) { newValue in
                    matomo.track(eventWithCategory: .settingsNotifications, name: "allNotifications", value: newValue)
                }

                IKDivider()

                if subscribedTopics != nil {
                    ForEach(AccountManager.instance.mailboxes) { mailbox in
                        Toggle(isOn: Binding(get: {
                            notificationsEnabled && subscribedTopics?.contains(mailbox.notificationTopicName) == true
                        }, set: { on in
                            matomo.track(eventWithCategory: .settingsNotifications, name: "mailboxNotifications", value: on)
                            if on && subscribedTopics?.contains(mailbox.notificationTopicName) == false {
                                subscribedTopics?.append(mailbox.notificationTopicName)
                            } else {
                                subscribedTopics?.removeAll { $0 == mailbox.notificationTopicName }
                            }
                        })) {
                            Text(mailbox.email)
                                .textStyle(.body)
                        }
                        .disabled(!notificationsEnabled)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 16)
        }
        .background(MailResourcesAsset.backgroundSecondaryColor.swiftUiColor)
        .navigationBarTitle(MailResourcesStrings.Localizable.settingsMailboxGeneralNotifications, displayMode: .inline)
        .onChange(of: notificationsEnabled) { enabled in
            if !enabled {
                subscribedTopics = []
            }
        }
        .task {
            await currentTopics()
        }
        .onDisappear {
            updateTopicsForCurrentUserIfNeeded()
        }
        .matomoView(view: [MatomoUtils.View.settingsView.displayName, "Notifications"])
    }

    func currentTopics() async {
        let currentSubscription = await notificationService.subscriptionForUser(id: AccountManager.instance.currentUserId)
        withAnimation {
            self.subscribedTopics = currentSubscription?.topics
        }
    }

    func updateTopicsForCurrentUserIfNeeded() {
        Task {
            guard let currentApiFetcher = AccountManager.instance.currentMailboxManager?.apiFetcher,
                  let subscribedTopics else { return }
            await notificationService.updateTopicsIfNeeded(subscribedTopics, userApiFetcher: currentApiFetcher)
        }
    }
}

struct SettingsNotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsNotificationsView()
    }
}
