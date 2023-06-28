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

struct UnavailableMailboxesView: View {
    @State var isShowingNewAccountView = false

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                ScrollView {
                    VStack(spacing: 16) {
                        MailResourcesAsset.logoText.swiftUIImage
                            .resizable()
                            .scaledToFit()
                            .frame(height: UIConstants.onboardingLogoHeight)
                            .padding(.top, UIConstants.onboardingLogoPaddingTop)

                        MailResourcesAsset.mailboxError.swiftUIImage
                            .resizable()
                            .scaledToFit()
                            .frame(height: 64)
                        Text(MailResourcesStrings.Localizable.lockedMailboxesTitle)
                            .textStyle(.header2)
                            .multilineTextAlignment(.center)
                        Text(MailResourcesStrings.Localizable.lockedMailboxesDescription)
                            .textStyle(.bodySecondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 24)

                        MailboxListView(currentMailbox: nil)
                    }
                }
                Spacer()

                NavigationLink {
                    AccountListView()
                } label: {
                    Text(MailResourcesStrings.Localizable.buttonAccountSwitch)
                        .textStyle(.bodyMediumAccent)
                }
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: 900)
        }
        .navigationViewStyle(.stack)
        .fullScreenCover(isPresented: $isShowingNewAccountView) {
            AppDelegate.orientationLock = .all
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
