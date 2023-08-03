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

import InfomaniakCoreUI
import MailCore
import MailResources
import SwiftUI

struct ThreadListManagerView: View {
    @Environment(\.isCompactWindow) private var isCompactWindow

    @AppStorage(UserDefaults.shared.key(.threadMode)) private var threadMode = DefaultPreferences.threadMode

    @EnvironmentObject private var splitViewManager: SplitViewManager
    @EnvironmentObject private var mailboxManager: MailboxManager

    var body: some View {
        Group {
            if let selectedFolder = splitViewManager.selectedFolder {
                if splitViewManager.showSearch {
                    SearchView(mailboxManager: mailboxManager, folder: selectedFolder)
                } else {
                    ThreadListView(mailboxManager: mailboxManager, folder: selectedFolder, isCompact: isCompactWindow)
                        .id(threadMode)
                }
            }
        }
        .id(mailboxManager.mailbox.id)
        .animation(.easeInOut(duration: 0.25), value: splitViewManager.showSearch)
    }
}

struct ThreadListManagerView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadListManagerView()
            .environmentObject(PreviewHelper.sampleMailboxManager)
    }
}
