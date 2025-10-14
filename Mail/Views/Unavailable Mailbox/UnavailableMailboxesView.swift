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

import DesignSystem
import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import InfomaniakLogin
import MailCore
import MailCoreUI
import MailResources
import SwiftUI

struct UnavailableMailboxesView: View {
    @InjectService private var matomo: MatomoUtils
    @InjectService private var accountManager: AccountManager

    @Environment(\.openURL) private var openURL

    @State private var presentedSwitchAccountUser: UserProfile?
    @State private var currentUser: UserProfile?

    let currentUserId: Int

    var body: some View {
        NavigationView {
            VStack(spacing: IKPadding.medium) {
                ScrollView {
                    VStack(spacing: IKPadding.medium) {
                        MailResourcesAsset.logoText.swiftUIImage
                            .resizable()
                            .scaledToFit()
                            .frame(height: UIConstants.onboardingLogoHeight)
                            .padding(.vertical, IKPadding.onBoardingLogoTop)

                        InformationBlockView(
                            icon: MailResourcesAsset.warningFill.swiftUIImage,
                            title: MailResourcesStrings.Localizable.lockedMailboxViewTitle,
                            message: MailResourcesStrings.Localizable.lockedMailboxViewDescription,
                            iconColor: MailResourcesAsset.orangeColor.swiftUIColor,
                            buttonAction: openFAQ,
                            buttonTitle: MailResourcesStrings.Localizable.readFAQ
                        )

                        if let currentUser {
                            UnavailableMailboxListView(currentUserId: currentUser.id)
                                .environment(\.currentUser, MandatoryEnvironmentContainer(value: currentUser))
                        }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    VStack(spacing: IKPadding.mini) {
                        Button(MailResourcesStrings.Localizable.buttonAccountLogOut) {
                            accountManager.removeAccountFor(userId: currentUserId)
                        }
                        .buttonStyle(.ikBorderless)
                        .task {
                            currentUser = await accountManager.userProfileStore.getUserProfile(id: currentUserId)
                        }
                    }
                    .controlSize(.large)
                    .ikButtonFullWidth(true)
                }
                .padding(.horizontal, value: .medium)
                .frame(maxWidth: 900)
                .matomoView(view: ["UnavailableMailboxesView"])
            }
        }
        .navigationViewStyle(.stack)
        .mailFloatingPanel(
            item: $presentedSwitchAccountUser,
            title: MailResourcesStrings.Localizable.titleMyAccount(accountManager.accounts.count)
        ) { currentUser in
            AccountListView(mailboxManager: nil)
                .environment(\.currentUser, MandatoryEnvironmentContainer(value: currentUser))
        }
    }

    private func openFAQ() {
        matomo.track(eventWithCategory: .noValidMailboxes, name: "readFAQ")
        openURL(URL(string: MailResourcesStrings.Localizable.faqUrl)!)
    }
}

#Preview {
    UnavailableMailboxesView(currentUserId: 0)
}
