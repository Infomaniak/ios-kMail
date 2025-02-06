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
    @LazyInjectService private var accountManager: AccountManager
    @LazyInjectService private var appLockHelper: AppLockHelper
    @LazyInjectService private var featureFlagsManageable: FeatureFlagsManageable
    @LazyInjectService private var matomo: MatomoUtils
    @LazyInjectService private var platformDetector: PlatformDetectable
    @LazyInjectService private var myKSuiteStore: MyKSuiteStore

    @Environment(\.currentUser) private var currentUser

    @EnvironmentObject private var mainViewState: MainViewState

    @AppStorage(UserDefaults.shared.key(.aiEngine)) private var aiEngine = DefaultPreferences.aiEngine
    @AppStorage(UserDefaults.shared.key(.threadDensity)) private var density = DefaultPreferences.threadDensity
    @AppStorage(UserDefaults.shared.key(.theme)) private var theme = DefaultPreferences.theme
    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor
    @AppStorage(UserDefaults.shared.key(.externalContent)) private var externalContent = DefaultPreferences.externalContent
    @AppStorage(UserDefaults.shared.key(.threadMode)) private var threadMode = DefaultPreferences.threadMode
    @AppStorage(UserDefaults.shared.key(.autoAdvance)) private var autoAdvance = DefaultPreferences.autoAdvance
    @AppStorage(UserDefaults.shared.key(.matomoAuthorized)) private var matomoAuthorized: Bool = DefaultPreferences
        .matomoAuthorized

    @State private var isShowingMyKSuiteDashboard = false
    @State private var myKSuiteMailbox: Mailbox?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // MARK: - Section: my kSuite

                if mainViewState.mailboxManager.mailbox.isFree {
                    Group {
                        SettingsSectionTitleView(title: "my kSuite")

                        if let myKSuiteMailbox, let mailboxManager = accountManager.getMailboxManager(for: myKSuiteMailbox) {
                            SettingsSubMenuCell(title: myKSuiteMailbox.email) {
                                MailboxSettingsView(mailboxManager: mailboxManager)
                            }
                        }

                        SettingsSubMenuLabel(title: MailResourcesStrings.Localizable.myKSuiteSubscriptionTitle)
                            .onTapGesture {
                                isShowingMyKSuiteDashboard = true
                            }
                            .sheet(isPresented: $isShowingMyKSuiteDashboard) {
                                MyKSuiteDashboardView(
                                    apiFetcher: mainViewState.mailboxManager.apiFetcher,
                                    userId: currentUser.value.id,
                                    userAvatar: nil
                                )
                            }
                    }
                    .task {
                        let configuration = {
                            @InjectService var mailboxInfosManager: MailboxInfosManager
                            return mailboxInfosManager.realmConfiguration
                        }()
                        let mailboxes = ObservedResults(Mailbox.self, configuration: configuration) {
                            $0.userId == currentUser.value.id && $0.isFree
                        }
                        myKSuiteMailbox = mailboxes.wrappedValue.first
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

                    SettingsSubMenuCell(
                        title: MailResourcesStrings.Localizable.buttonAddExistingAddress
                    ) {
                        AddMailboxView()
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

                    // MARK: AI Writer

                    if featureFlagsManageable.isEnabled(.aiMailComposer) {
                        SettingsSubMenuCell(title: MailResourcesStrings.Localizable.aiPromptTitle, subtitle: aiEngine.title) {
                            SettingsAIEngineOptionView()
                        }
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
                            userDefaultKeySentry: UserDefaults.shared.key(.sentryAuthorized)
                        )
                        .onChange(of: matomoAuthorized) { newValue in
                            #if DEBUG && !TEST
                            matomo.optOut(true)
                            #else
                            matomo.optOut(!newValue)
                            #endif
                        }
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
    }
}

#Preview {
    SettingsView()
}
