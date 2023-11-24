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
import InfomaniakDI
import MailCore
import MailResources
import RealmSwift
import SwiftUI

struct LoadMoreButton: View {
    @LazyInjectService private var matomo: MatomoUtils

    @EnvironmentObject private var mailboxManager: MailboxManager

    @State private var isLoadingMore = false

    @ObservedRealmObject var currentFolder: Folder

    private var shouldDisplay: Bool {
        return !currentFolder.isHistoryComplete && currentFolder.lastUpdate != nil
    }

    var body: some View {
        Group {
            if isLoadingMore {
                ProgressView()
                    .id(UUID())
                    .frame(maxWidth: .infinity)
            } else if shouldDisplay {
                Button(MailResourcesStrings.Localizable.buttonLoadMore) {
                    withAnimation {
                        isLoadingMore = true
                    }

                    Task {
                        await tryOrDisplayError {
                            matomo.track(eventWithCategory: .threadList, name: "loadMore")
                            _ = try await mailboxManager.fetchOnePage(
                                folder: currentFolder,
                                direction: .previous
                            )
                            isLoadingMore = false
                        }
                    }
                }
                .buttonStyle(IKLinkButtonStyle())
                .controlSize(.small)
            }
        }
        .padding(.vertical, value: .small)
        .threadListCellAppearance()
    }
}
