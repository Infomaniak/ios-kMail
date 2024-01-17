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

import Contacts
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailResources
import SwiftUI

enum AuthorizationSlide: Int {
    case contacts
    case notifications
}

struct AuthorizationView: View {
    @LazyInjectService private var accountManager: AccountManager
    @LazyInjectService private var matomo: MatomoUtils

    @EnvironmentObject private var navigationState: RootViewState

    @State private var selection = AuthorizationSlide.contacts.rawValue
    @State private var isScrollDisabled = true

    private var slides = Slide.authorizationSlides

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selection) {
                ForEach(slides) { slide in
                    SlideView(slide: slide)
                        .tag(slide.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea(edges: .top)
            .disabled(isScrollDisabled)
            .overlay(alignment: .top) {
                MailResourcesAsset.logoText.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(height: UIConstants.onboardingLogoHeight)
                    .padding(.top, UIPadding.onBoardingLogoTop)
            }

            VStack(spacing: UIPadding.small) {
                Button(MailResourcesStrings.Localizable.contentDescriptionButtonNext) {
                    if selection == AuthorizationSlide.contacts.rawValue {
                        Task {
                            let accessAllowed = await (try? CNContactStore().requestAccess(for: .contacts))
                            isScrollDisabled = false
                            withAnimation {
                                selection = AuthorizationSlide.notifications.rawValue
                                isScrollDisabled = true
                            }
                            if accessAllowed != nil {
                                try await accountManager.currentMailboxManager?.contactManager.refreshContactsAndAddressBooks()
                            }
                        }
                    } else {
                        Task {
                            await NotificationsHelper.askForPermissions()
                            navigationState.transitionToRootViewDestination(.mainView)
                        }
                    }
                }
                .buttonStyle(.ikPlain)
                .controlSize(.large)
                .ikButtonFullWidth(true)
            }
            .padding(.horizontal, value: .medium)
            .padding(.bottom, UIPadding.onBoardingBottomButtons)
        }
        .matomoView(view: [MatomoUtils.View.onboarding.displayName, "Authorization"])
    }
}

struct AuthorizationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthorizationView()
    }
}
