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
    @LazyInjectService private var accountManager: AccountManager
    
    private var accountManagerObservation: AnyCancellable?

    @Published private(set) var rootViewState: RootViewState
    @Published var messageReply: MessageReply?
    @Published var editedMessageDraft: Draft?

    /// Represents the state of navigation
    ///
    /// The selected thread is the last in collection, by convention.
    @Published var threadPath = [Thread]()

    init() {
        @InjectService var localAccountManager: AccountManager
        if localAccountManager.currentAccount != nil,
           let currentMailboxManager = localAccountManager.currentMailboxManager {
            rootViewState = .mainView(currentMailboxManager)
        } else if !localAccountManager.mailboxes.isEmpty && localAccountManager.mailboxes.allSatisfy({ !$0.isAvailable }) {
            rootViewState = .unavailableMailboxes
        } else {
            rootViewState = .onboarding
        }

        accountManagerObservation = accountManager.objectWillChange.receive(on: RunLoop.main).sink { [weak self] in
            self?.switchToCurrentMailboxManagerIfPossible()
        }
    }

    func transitionToRootViewDestination(_ destination: RootViewDestination) {
        withAnimation {
            switch destination {
            case .appLocked:
                rootViewState = .appLocked
            case .mainView:
                switchToCurrentMailboxManagerIfPossible()
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
            && accountManager.currentAccount != nil {
            transitionToRootViewDestination(.appLocked)
        }
    }

    private func switchToCurrentMailboxManagerIfPossible() {
        if accountManager.currentAccount != nil,
           let currentMailboxManager = accountManager.currentMailboxManager {
            if rootViewState != .mainView(currentMailboxManager) {
                rootViewState = .mainView(currentMailboxManager)
            }
        } else if !accountManager.mailboxes.isEmpty && accountManager.mailboxes.allSatisfy({ !$0.isAvailable }) {
            rootViewState = .unavailableMailboxes
        } else {
            rootViewState = .onboarding
        }
    }
}
