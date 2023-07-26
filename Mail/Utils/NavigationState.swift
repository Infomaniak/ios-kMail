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
import Foundation
import InfomaniakCore
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import SwiftUI

enum RootViewState: Equatable, Hashable, Identifiable {
    var id: Int {
        return hashValue
    }

    static func == (lhs: RootViewState, rhs: RootViewState) -> Bool {
        switch (lhs, rhs) {
        case (.appLocked, .appLocked):
            return true
        case (.onboarding, .onboarding):
            return true
        case (.noMailboxes, .noMailboxes):
            return true
        case (.unavailableMailboxes, .unavailableMailboxes):
            return true
        case (.mainView(let lhsMailboxManager), .mainView(let rhsMailboxManager)):
            return lhsMailboxManager.mailbox.objectId == rhsMailboxManager.mailbox.objectId
        default:
            return false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .appLocked:
            hasher.combine("applocked")
        case .mainView(let mailboxManager):
            hasher.combine("mainView\(mailboxManager.mailbox.objectId)")
        case .onboarding:
            hasher.combine("onboarding")
        case .noMailboxes:
            hasher.combine("noMailboxes")
        case .unavailableMailboxes:
            hasher.combine("unavailableMailboxes")
        }
    }

    case appLocked
    case mainView(MailboxManager)
    case onboarding
    case noMailboxes
    case unavailableMailboxes
}

enum RootViewDestination {
    case appLocked
    case mainView
    case onboarding
    case noMailboxes
    case unavailableMailboxes
}

@MainActor
/// Something that represents the state of navigation
class NavigationState: ObservableObject {
    @LazyInjectService private var appLockHelper: AppLockHelper

    private var accountManagerObservation: AnyCancellable?

    @Published private(set) var rootViewState: RootViewState
    @Published var messageReply: MessageReply?
    @Published var editedMessageDraft: Draft?

    /// Represents the state of navigation
    ///
    /// The selected thread is the last in collection, by convention.
    @Published var threadPath = [Thread]()

    private(set) var account: Account?

    init() {
        @InjectService var accountManager: AccountManager

        account = accountManager.getCurrentAccount()
        rootViewState = NavigationState.getMainViewStateIfPossible()

        accountManagerObservation = accountManager.objectWillChange.receive(on: RunLoop.main).sink { [weak self] in
            self?.account = accountManager.getCurrentAccount()
            self?.rootViewState = NavigationState.getMainViewStateIfPossible()
        }
    }

    static func getMainViewStateIfPossible() -> RootViewState {
        @InjectService var accountManager: AccountManager

        if let currentAccount = accountManager.getCurrentAccount() {
            if let currentMailboxManager = accountManager.currentMailboxManager {
                return .mainView(currentMailboxManager)
            } else {
                let mailboxes = MailboxInfosManager.instance.getMailboxes(for: currentAccount.userId)
                if !mailboxes.isEmpty && mailboxes.allSatisfy({ !$0.isAvailable }) {
                    return .unavailableMailboxes
                }
            }
        }

        return .onboarding
    }

    func transitionToRootViewDestination(_ destination: RootViewDestination) {
        withAnimation {
            switch destination {
            case .appLocked:
                rootViewState = .appLocked
            case .mainView:
                rootViewState = NavigationState.getMainViewStateIfPossible()
            case .onboarding:
                rootViewState = .onboarding
            case .noMailboxes:
                rootViewState = .noMailboxes
            case .unavailableMailboxes:
                rootViewState = .unavailableMailboxes
            }
        }
    }

    func transitionToLockViewIfNeeded() {
        if UserDefaults.shared.isAppLockEnabled
            && appLockHelper.isAppLocked
            && account != nil {
            transitionToRootViewDestination(.appLocked)
        }
    }
}
