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
import SwiftUI

public enum RootViewState: Equatable {
    public static func == (lhs: RootViewState, rhs: RootViewState) -> Bool {
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

    case appLocked
    case mainView(MailboxManager)
    case onboarding
    case noMailboxes
    case unavailableMailboxes
}

public enum RootViewDestination {
    case appLocked
    case mainView
    case onboarding
    case noMailboxes
    case unavailableMailboxes
}

@MainActor
/// Something that represents the state of navigation
public class NavigationState: ObservableObject {
    @LazyInjectService private var appLockHelper: AppLockHelper

    private var accountManagerObservation: AnyCancellable?

    @Published public private(set) var rootViewState: RootViewState
    @Published public var editedDraft: EditedDraft?
    @Published public var messagesToMove: [Message]?

    /// Represents the state of navigation
    ///
    /// The selected thread is the last in collection, by convention.
    @Published public var threadPath = [Thread]()
    @Published public var selectedFolder: Folder?

    @Published public var isShowingSearch = false
    @Published public var isShowingReviewAlert = false

    public private(set) var account: Account?

    public init() {
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
        @InjectService var mailboxInfosManager: MailboxInfosManager

        if let currentAccount = accountManager.getCurrentAccount() {
            if let currentMailboxManager = accountManager.currentMailboxManager {
                return .mainView(currentMailboxManager)
            } else {
                let mailboxes = mailboxInfosManager.getMailboxes(for: currentAccount.userId)
                if !mailboxes.isEmpty && mailboxes.allSatisfy({ !$0.isAvailable }) {
                    return .unavailableMailboxes
                }
            }
        }

        return .onboarding
    }

    public func transitionToRootViewDestination(_ destination: RootViewDestination) {
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

    public func transitionToLockViewIfNeeded() {
        if UserDefaults.shared.isAppLockEnabled
            && appLockHelper.isAppLocked
            && account != nil {
            transitionToRootViewDestination(.appLocked)
        }
    }
}
