/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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

import InfomaniakCore
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailResources
import SwiftUI

@available(iOS 16.0, *)
struct NewMessageCommand: View {
    @LazyInjectService private var matomo: MatomoUtils

    @EnvironmentObject var quickActionService: QuickActionService
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.openWindow) private var openWindow

    let mailboxManager: MailboxManager?

    var body: some View {
        Button(MailResourcesStrings.Localizable.buttonNewMessage) {
            guard let mailboxManager else { return }
            newMessage(mailboxManager: mailboxManager)
        }
        .keyboardShortcut("n")
        .disabled(mailboxManager == nil)
        .onChange(of: scenePhase) { newValue in
            switch newValue {
            case .active:
                performActionIfNeeded()
            default:
                break
            }
        }
    }

    func newMessage(mailboxManager: MailboxManager) {
        matomo.track(eventWithCategory: .menuAction, name: "newMessage")
        openWindow(
            id: DesktopWindowIdentifier.composeWindowIdentifier,
            value: ComposeMessageIntent.new(originMailboxManager: mailboxManager)
        )
    }

    func performActionIfNeeded() {
        guard let quickAction = quickActionService.quickAction else { return }

        switch quickAction {
        case .newMessage:
            newMessage(mailboxManager: mailboxManager!)
        case .search:
            // Recherche
            newMessage(mailboxManager: mailboxManager!)
        case .support:
            // A changer
            newMessage(mailboxManager: mailboxManager!)
        }

        quickActionService.quickAction = nil
    }
}
