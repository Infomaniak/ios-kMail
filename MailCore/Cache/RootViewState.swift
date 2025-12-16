/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

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

import Combine
import Contacts
import Foundation
import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakCoreDB
import InfomaniakDI
import InfomaniakLogin
import SwiftUI

public enum RootViewType: Equatable {
    public static func == (lhs: RootViewType, rhs: RootViewType) -> Bool {
        switch (lhs, rhs) {
        case (.appLocked, .appLocked):
            return true
        case (.onboarding, .onboarding):
            return true
        case (.authorization, .authorization):
            return true
        case (.noMailboxes, .noMailboxes):
            return true
        case (.unavailableMailboxes(let lhsAccount), .unavailableMailboxes(let rhsAccount)):
            return lhsAccount.accessToken == rhsAccount.accessToken
        case (.updateRequired, .updateRequired):
            return true
        case (.mainView(let lhsUser, let lhsMainViewState), .mainView(let rhsUser, let rhsMainViewState)):
            return lhsUser.id == rhsUser.id && lhsMainViewState.mailboxManager == rhsMainViewState.mailboxManager
        case (.preloading, .preloading):
            return true
        default:
            return false
        }
    }

    case appLocked
    case mainView(UserProfile, MainViewState)
    case onboarding
    case authorization
    case noMailboxes
    case unavailableMailboxes(ApiToken)
    case updateRequired
    case preloading
}

/// Something that represents the state of the root view
@MainActor
public class RootViewState: ObservableObject {
    @LazyInjectService private var appLockHelper: AppLockHelper

    private var accountManagerObservation: AnyCancellable?

    @Published public private(set) var state: RootViewType

    public init() {
        @InjectService var accountManager: AccountManager

        state = .preloading

        accountManagerObservation = accountManager.objectWillChange.receive(on: RunLoop.main).sink { [weak self] in
            Task {
                let account = accountManager.getCurrentAccount()
                await self?.transitionToMainViewIfPossible(targetAccount: account, targetMailbox: nil)
            }
        }
    }

    public func transitionToRootViewState(_ newState: RootViewType) {
        withAnimation {
            state = newState
        }
    }

    public func transitionToMainViewIfPossible(targetAccount: ApiToken?, targetMailbox: Mailbox?) async {
        @InjectService var accountManager: AccountManager
        @InjectService var mailboxInfosManager: MailboxInfosManager
        @InjectService var mainViewStateStore: MainViewStateStore

        guard let currentAccount = targetAccount ?? accountManager.getCurrentAccount() else {
            transitionToRootViewState(.onboarding)
            return
        }

        guard CNContactStore.authorizationStatus(for: .contacts) != .notDetermined,
              await UNUserNotificationCenter.current().notificationSettings().authorizationStatus != .notDetermined else {
            transitionToRootViewState(.authorization)
            return
        }

        let targetMailboxManager: MailboxManager?
        if let targetMailbox {
            targetMailboxManager = accountManager.getMailboxManager(for: targetMailbox)
        } else {
            targetMailboxManager = accountManager.currentMailboxManager
        }

        if let targetMailboxManager,
           let initialFolder = targetMailboxManager.getFolder(with: .inbox)?.freezeIfNeeded(),
           let currentUser = await accountManager.getCurrentUser() {
            let mainViewState = await mainViewStateStore.getOrCreateMainViewState(
                for: targetMailboxManager,
                initialFolder: initialFolder
            )

            transitionToRootViewState(.mainView(currentUser, mainViewState))
        } else {
            let mailboxes = mailboxInfosManager.getMailboxes(for: currentAccount.userId)

            if !mailboxes.isEmpty && mailboxes.allSatisfy({ $0.isLocked }) {
                transitionToRootViewState(.unavailableMailboxes(currentAccount))
            } else {
                transitionToRootViewState(.preloading)
            }
        }
    }

    public func transitionToLockViewIfNeeded() {
        @InjectService var accountManager: AccountManager
        if UserDefaults.shared.isAppLockEnabled && appLockHelper.isAppLocked && !accountManager.accounts.isEmpty {
            transitionToRootViewState(.appLocked)
        }
    }
}
