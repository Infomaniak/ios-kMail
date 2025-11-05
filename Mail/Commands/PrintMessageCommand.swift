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

import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakDI
import MailCore
import MailResources
import SwiftUI

struct PrintMessageCommand: View {
    @ObservedObject var mainViewState: MainViewState

    var body: some View {
        Button(MailResourcesStrings.Localizable.actionPrint) {
            printCurrentMessage(mainViewState: mainViewState)
        }
        .keyboardShortcut("p")
        .disabled(mainViewState.selectedThread?.lastMessageFromFolder == nil)
    }

    func printCurrentMessage(mainViewState: MainViewState) {
        @InjectService var matomo: MatomoUtils
        matomo.track(eventWithCategory: .menuAction, name: "print")

        guard let message = mainViewState.selectedThread?.lastMessageFromFolder else { return }
        NotificationCenter.default.post(name: Notification.Name.printNotification, object: message)
    }
}
