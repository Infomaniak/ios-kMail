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

import Foundation
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
        }
    }

    case appLocked
    case mainView(MailboxManager)
    case onboarding
}

enum RootViewDestination {
    case appLocked
    case mainView
    case onboarding
}

@MainActor
class NavigationStore: ObservableObject {
    private let accountManager = AccountManager.instance
    @Published private(set) var rootViewState: RootViewState
    @Published var messageReply: MessageReply?
    @Published var threadPath = [Thread]()

    init() {
        if accountManager.currentAccount != nil,
           let currentMailboxManager = accountManager.currentMailboxManager {
            rootViewState = .mainView(currentMailboxManager)
        } else {
            rootViewState = .onboarding
        }
    }

    func transitionToRootViewDestination(_ destination: RootViewDestination) {
        withAnimation {
            switch destination {
            case .appLocked:
                rootViewState = .appLocked
            case .mainView:
                if accountManager.currentAccount != nil,
                   let currentMailboxManager = accountManager.currentMailboxManager {
                    rootViewState = .mainView(currentMailboxManager)
                } else {
                    rootViewState = .onboarding
                }
            case .onboarding:
                rootViewState = .onboarding
            }
        }
    }
}
