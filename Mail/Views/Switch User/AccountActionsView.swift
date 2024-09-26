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

import InfomaniakCoreCommonUI
import InfomaniakDI
import MailCore
import MailCoreUI
import SwiftModalPresentation
import SwiftUI

struct AccountActionsView: View {
    @LazyInjectService private var matomo: MatomoUtils
    @LazyInjectService private var orientationManager: OrientationManageable

    @Environment(\.currentUser) private var currentUser

    @ModalState(context: ContextKeys.account) private var isShowingLogoutAlert = false
    @State private var isShowingNewAccountView = false

    private var actions: [Action] {
        return [.addAccount, .logoutAccount]
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(actions) { action in
                Button {
                    handleAction(action)
                } label: {
                    ActionButtonLabel(action: action)
                }
            }
        }
        .fullScreenCover(isPresented: $isShowingNewAccountView, onDismiss: {
            orientationManager.setOrientationLock(.all)
        }, content: {
            SingleOnboardingView()
        })
        .customAlert(isPresented: $isShowingLogoutAlert) {
            LogoutConfirmationView(user: currentUser.value)
        }
    }

    // MARK: - Actions

    private func handleAction(_ action: Action) {
        switch action {
        case .addAccount:
            addAccount(action)
        case .logoutAccount:
            logoutAccount(action)
        default:
            return
        }
    }

    private func addAccount(_ action: Action) {
        matomo.track(eventWithCategory: .account, name: action.matomoName)
        isShowingNewAccountView.toggle()
    }

    private func logoutAccount(_ action: Action) {
        matomo.track(eventWithCategory: .account, name: action.matomoName)
        isShowingLogoutAlert.toggle()
    }
}

#Preview {
    AccountActionsView()
}
