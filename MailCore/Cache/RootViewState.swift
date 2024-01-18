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

import Combine
import Contacts
import Foundation
import InfomaniakCore
import InfomaniakCoreUI
import InfomaniakDI
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
        case (.unavailableMailboxes, .unavailableMailboxes):
            return true
        case (.mainView(let lhsMailboxManager, let lhsFolder), .mainView(let rhsMailboxManager, let rhsFolder)):
            return lhsMailboxManager == rhsMailboxManager
                && lhsFolder.remoteId == rhsFolder.remoteId
        case (.preloading(let lhsAccount), .preloading(let rhsAccount)):
            return lhsAccount == rhsAccount
        default:
            return false
        }
    }

    case appLocked
    case mainView(MailboxManager, Folder)
    case onboarding
    case authorization
    case noMailboxes
    case unavailableMailboxes
    case preloading(Account)
}

public enum RootViewDestination {
    case appLocked
    case mainView
    case onboarding
    case noMailboxes
    case unavailableMailboxes
}

/// Something that represents the state of the root view
@MainActor
public class RootViewState: ObservableObject {
    @LazyInjectService private var appLockHelper: AppLockHelper

    private var accountManagerObservation: AnyCancellable?

    @Published public private(set) var state: RootViewType

    public private(set) var account: Account?

    public init() {
        @InjectService var accountManager: AccountManager

        account = accountManager.getCurrentAccount()
        state = RootViewState.getMainViewStateIfPossible()

        accountManagerObservation = accountManager.objectWillChange.receive(on: RunLoop.main).sink { [weak self] in
            self?.account = accountManager.getCurrentAccount()
            withAnimation {
                self?.state = RootViewState.getMainViewStateIfPossible()
            }
        }
    }

    static func getMainViewStateIfPossible() -> RootViewType {
        @InjectService var accountManager: AccountManager
        @InjectService var mailboxInfosManager: MailboxInfosManager

        guard let currentAccount = accountManager.getCurrentAccount() else {
            return .onboarding
        }

        guard CNContactStore.authorizationStatus(for: .contacts) != .notDetermined else {
            return .authorization
        }

        if let currentMailboxManager = accountManager.currentMailboxManager,
           let initialFolder = currentMailboxManager.getFolder(with: .inbox)?.freezeIfNeeded() {
            return .mainView(currentMailboxManager, initialFolder)
        } else {
            let mailboxes = mailboxInfosManager.getMailboxes(for: currentAccount.userId)

            if !mailboxes.isEmpty && mailboxes.allSatisfy({ !$0.isAvailable }) {
                return .unavailableMailboxes
            } else {
                return .preloading(currentAccount)
            }
        }
    }

    public func transitionToRootViewDestination(_ destination: RootViewDestination) {
        withAnimation {
            switch destination {
            case .appLocked:
                state = .appLocked
            case .mainView:
                state = RootViewState.getMainViewStateIfPossible()
            case .onboarding:
                state = .onboarding
            case .noMailboxes:
                state = .noMailboxes
            case .unavailableMailboxes:
                state = .unavailableMailboxes
            }
        }
    }

    public func transitionToLockViewIfNeeded() {
        if UserDefaults.shared.isAppLockEnabled
            && appLockHelper.isAppLocked
            && account != nil {
            transitionToRootViewDestination(.appLocked)
        }
    }
}
