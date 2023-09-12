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

import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailResources
import SwiftUI

struct UnavailableMailboxesView: View {
    @LazyInjectService private var orientationManager: OrientationManageable
    @LazyInjectService private var matomo: MatomoUtils

    @State private var isShowingNewAccountView = false
    @State private var isShowingAddMailboxView = false

    var body: some View {
        NavigationView {
            VStack(spacing: UIPadding.regular) {
                ScrollView {
                    VStack(spacing: UIPadding.regular) {
                        MailResourcesAsset.logoText.swiftUIImage
                            .resizable()
                            .scaledToFit()
                            .frame(height: UIConstants.onboardingLogoHeight)
                            .padding(.top, UIPadding.onBoardingLogoTop)

                        MailResourcesAsset.mailboxError.swiftUIImage
                            .resizable()
                            .scaledToFit()
                            .frame(height: 64)
                        Text(MailResourcesStrings.Localizable.lockedMailboxTitlePlural)
                            .textStyle(.header2)
                            .multilineTextAlignment(.center)
                        Text(MailResourcesStrings.Localizable.lockedMailboxDescriptionPlural)
                            .textStyle(.bodySecondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, value: .medium)

                        UnavailableMailboxListView()
                    }
                }

                Spacer()

                NavigationLink(isActive: $isShowingAddMailboxView) {
                    AddMailboxView()
                } label: {
                    MailButton(label: MailResourcesStrings.Localizable.buttonAddEmailAddress) {
                        matomo.track(eventWithCategory: .noValidMailboxes, name: "addMailbox")
                        isShowingAddMailboxView = true
                    }
                    .mailButtonFullWidth(true)
                    .mailButtonStyle(.large)
                }

                NavigationLink {
                    // We cannot provide a mailbox manager here
                    AccountListView(mailboxManager: nil)
                } label: {
                    Text(MailResourcesStrings.Localizable.buttonAccountSwitch)
                        .textStyle(.bodyMediumAccent)
                }
                .simultaneousGesture(
                    TapGesture()
                        .onEnded {
                            matomo.track(eventWithCategory: .noValidMailboxes, name: "switchAccount")
                        }
                )
            }
            .padding(.horizontal, value: .regular)
            .frame(maxWidth: 900)
            .matomoView(view: ["UnavailableMailboxesView"])
        }
        .navigationViewStyle(.stack)
        .fullScreenCover(isPresented: $isShowingNewAccountView) {
            orientationManager.setOrientationLock(.all)
        } content: {
            OnboardingView(page: 4, isScrollEnabled: false)
        }
    }
}

struct UnavailableMailboxesView_Previews: PreviewProvider {
    static var previews: some View {
        UnavailableMailboxesView()
    }
}
