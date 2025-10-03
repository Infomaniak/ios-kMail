/*
 Infomaniak Mail - iOS App
 Copyright (C) 2023 Infomaniak Network SA

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

import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import InfomaniakPrivacyManagement
import MailCore
import MailCoreUI
import MailResources
import MyKSuite
import RealmSwift
import SwiftModalPresentation
import SwiftUI

struct SettingsView: View {
    @InjectService private var accountManager: AccountManager
    @InjectService private var appLockHelper: AppLockHelper
    @InjectService private var platformDetector: PlatformDetectable
    @InjectService private var myKSuiteStore: MyKSuiteStore
    @LazyInjectService private var matomo: MatomoUtils

    @Environment(\.currentUser) private var currentUser

    @EnvironmentObject private var mainViewState: MainViewState

    @AppStorage(UserDefaults.shared.key(.threadDensity)) private var density = DefaultPreferences.threadDensity
    @AppStorage(UserDefaults.shared.key(.theme)) private var theme = DefaultPreferences.theme
    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor
    @AppStorage(UserDefaults.shared.key(.externalContent)) private var externalContent = DefaultPreferences.externalContent
    @AppStorage(UserDefaults.shared.key(.threadMode)) private var threadMode = DefaultPreferences.threadMode
    @AppStorage(UserDefaults.shared.key(.autoAdvance)) private var autoAdvance = DefaultPreferences.autoAdvance

    @State private var isShowingMyKSuiteDashboard = false
    @State private var myKSuiteMailbox: Mailbox?
    @State private var myKSuite: MyKSuite?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // MARK: - Section: my kSuite

                if let myKSuite,
                   let myKSuiteMailbox,
                   let mailboxManager = accountManager.getMailboxManager(for: myKSuiteMailbox) {
                    Group {
                        SettingsSectionTitleView(title: myKSuite.isFree ? "my kSuite" : "my kSuite+")

                        SettingsSubMenuCell(title: myKSuiteMailbox.email) {
                            MailboxSettingsView(mailboxManager: mailboxManager)
                        }

                        SettingsSubMenuLabel(title: MailResourcesStrings.Localizable.myKSuiteSubscriptionTitle)
                            .onTapGesture {
                                isShowingMyKSuiteDashboard = true
                                matomo.track(eventWithCategory: .myKSuite, name: "openDashboard")
                            }
                            .sheet(isPresented: $isShowingMyKSuiteDashboard) {
                                MyKSuiteDashboardView(
                                    apiFetcher: mailboxManager.apiFetcher,
                                    userId: currentUser.value.id
                                ) {
                                    AvatarView(
                                        mailboxManager: mailboxManager,
                                        contactConfiguration: .user(user: currentUser.value),
                                        size: 24
                                    )
                                }
                            }

                        IKDivider()
                    }
                }

                // MARK: - Section: Email Addresses

                Group {
                    SettingsSectionTitleView(title: MailResourcesStrings.Localizable.settingsSectionEmailAddresses)

                    ForEachMailboxView(userId: currentUser.value.id,
                                       excludedMailboxIds: [myKSuiteMailbox?.mailboxId ?? 0]) { mailbox in
                        if let mailboxManager = accountManager.getMailboxManager(for: mailbox) {
                            SettingsSubMenuCell(title: mailbox.email) {
                                MailboxSettingsView(mailboxManager: mailboxManager)
                            }
                        }
                    }

                    IKDivider()
                }

                // MARK: - Section: General

                Group {
                    SettingsSectionTitleView(title: MailResourcesStrings.Localizable.settingsSectionGeneral)

                    // MARK: App Lock

                    if appLockHelper.isAvailable() {
                        SettingsToggleCell(
                            title: MailResourcesStrings.Localizable.settingsAppLock,
                            userDefaults: \.isAppLockEnabled,
                            matomoCategory: .settingsGeneral,
                            matomoName: "lock"
                        )
                    }

                    // MARK: Notifications

                    DeepLinkSettingsSubMenuCell(
                        title: MailResourcesStrings.Localizable.settingsMailboxGeneralNotifications,
                        value: .notifications
                    )

                    // MARK: Sync Calendar/Contacts

                    if !platformDetector.isMac {
                        Button {
                            matomo.track(eventWithCategory: .syncAutoConfig, name: "openFromSettings")
                            mainViewState.isShowingSyncProfile = true
                        } label: {
                            SettingsSubMenuLabel(title: MailResourcesStrings.Localizable.syncCalendarsAndContactsTitle)
                        }
                        .buttonStyle(.plain)
                    }

                    // MARK: Auto Advance

                    SettingsSubMenuCell(
                        title: MailResourcesStrings.Localizable.settingsAutoAdvanceTitle,
                        subtitle: autoAdvance.description
                    ) {
                        SettingsAutoAdvanceView()
                    }

                    // MARK: External Content

                    SettingsSubMenuCell(
                        title: MailResourcesStrings.Localizable.settingsExternalContentTitle,
                        subtitle: externalContent.title
                    ) {
                        SettingsOptionView(
                            title: MailResourcesStrings.Localizable.settingsExternalContentTitle,
                            subtitle: MailResourcesStrings.Localizable.settingsExternalContentDescription,
                            keyPath: \.displayExternalContent,
                            matomoCategory: .settingsDisplayExternalContent,
                            matomoName: \.rawValue
                        )
                    }

                    IKDivider()
                }

                // MARK: - Section: Appearance

                Group {
                    SettingsSectionTitleView(title: MailResourcesStrings.Localizable.settingsSectionAppearance)

                    // MARK: Thread Density

                    SettingsSubMenuCell(
                        title: MailResourcesStrings.Localizable.settingsThreadListDensityTitle,
                        subtitle: density.title
                    ) {
                        SettingsThreadDensityOptionView()
                    }

                    // MARK: Theme

                    SettingsSubMenuCell(title: MailResourcesStrings.Localizable.settingsThemeTitle, subtitle: theme.title) {
                        SettingsOptionView<Theme>(
                            title: MailResourcesStrings.Localizable.settingsThemeTitle,
                            subtitle: MailResourcesStrings.Localizable.settingsThemeDescription,
                            keyPath: \.theme,
                            matomoCategory: .settingsTheme,
                            matomoName: \.rawValue
                        )
                    }

                    // MARK: Accent Color

                    SettingsSubMenuCell(
                        title: MailResourcesStrings.Localizable.settingsAccentColor,
                        subtitle: accentColor.title
                    ) {
                        SettingsOptionView(
                            title: MailResourcesStrings.Localizable.settingsAccentColor,
                            subtitle: MailResourcesStrings.Localizable.settingsAccentColorDescription,
                            keyPath: \.accentColor,
                            matomoCategory: .settingsAccentColor,
                            matomoName: \.rawValue
                        )
                    }

                    // MARK: Swipe Actions

                    SettingsSubMenuCell(title: MailResourcesStrings.Localizable.settingsSwipeActionsTitle) {
                        SettingsSwipeActionsView()
                    }

                    // MARK: Thread Mode

                    SettingsSubMenuCell(
                        title: MailResourcesStrings.Localizable.settingsThreadModeTitle,
                        subtitle: threadMode.title
                    ) {
                        SettingsThreadModeView()
                    }

                    IKDivider()
                }

                // MARK: - Section: Data and privacy

                Group {
                    SettingsSectionTitleView(
                        title: MailResourcesStrings.Localizable.settingsSectionDataPrivacy
                    )

                    SettingsSubMenuCell(
                        title: MailResourcesStrings.Localizable.settingsDataManagementTitle
                    ) {
                        PrivacyManagementView(
                            urlRepository: URLConstants.githubRepository.url,
                            backgroundColor: MailResourcesAsset.backgroundColor.swiftUIColor,
                            illustration: accentColor.dataPrivacyImage.swiftUIImage,
                            userDefaultStore: .shared,
                            userDefaultKeyMatomo: UserDefaults.shared.key(.matomoAuthorized),
                            userDefaultKeySentry: UserDefaults.shared.key(.sentryAuthorized),
                            matomo: matomo
                        )
                    }

                    SettingsSubMenuCell(
                        title: MailResourcesStrings.Localizable.settingsAccountManagementTitle
                    ) {
                        SettingsAccountManagementView(user: currentUser.value)
                    }
                }
            }
        }
        .background(MailResourcesAsset.backgroundColor.swiftUIColor)
        .navigationBarTitle(MailResourcesStrings.Localizable.settingsTitle, displayMode: .inline)
        .backButtonDisplayMode(.minimal)
        .matomoView(view: [MatomoUtils.View.settingsView.displayName, "General"])
        .task {
            await loadMyKSuite()
        }
    }

    func loadMyKSuite() async {
        myKSuite = await myKSuiteStore.getMyKSuite(id: currentUser.value.id)

        guard myKSuite != nil else { return }

        @InjectService var mailboxInfosManager: MailboxInfosManager
        let mailboxes = ObservedResults(Mailbox.self, configuration: mailboxInfosManager.realmConfiguration) {
            $0.userId == currentUser.value.id && $0.isFree
        }
        myKSuiteMailbox = mailboxes.wrappedValue.first
    }
}

#Preview {
    SettingsView()
        .environment(\.currentUser, MandatoryEnvironmentContainer(value: PreviewHelper.sampleUser))
}
