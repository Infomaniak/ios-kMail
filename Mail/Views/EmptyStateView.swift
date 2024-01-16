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

import InfomaniakCore
import InfomaniakCoreUI
import MailCore
import MailResources
import SwiftUI

struct EmptyStateView: View {
    let image: Image
    let title: String
    let description: String

    var withFABPadding = true

    let matomoName: String

    var body: some View {
        VStack(spacing: 0) {
            image
                .padding(.bottom, value: .medium)

            Text(title)
                .textStyle(.header2)
                .padding(.bottom, value: .verySmall)
            Text(description)
                .textStyle(.bodySecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, value: .large)
        .padding(.bottom, withFABPadding ? UIPadding.floatingButtonBottom + 56 : 0)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .matomoView(view: [MatomoUtils.View.threadListView.displayName, "Empty\(matomoName)View"])
        .ignoresSafeArea(.keyboard)
    }
}

extension EmptyStateView {
    static let emptyInbox = EmptyStateView(
        image: MailResourcesAsset.emptyStateInbox.swiftUIImage,
        title: MailResourcesStrings.Localizable.emptyStateInboxTitle,
        description: MailResourcesStrings.Localizable.emptyStateInboxDescription,
        matomoName: "Inbox"
    )

    static let emptyTrash = EmptyStateView(
        image: MailResourcesAsset.emptyStateTrash.swiftUIImage,
        title: MailResourcesStrings.Localizable.emptyStateTrashTitle,
        description: MailResourcesStrings.Localizable.emptyStateTrashDescription,
        matomoName: "Trash"
    )

    static let emptyFolder = EmptyStateView(
        image: MailResourcesAsset.emptyStateFolder.swiftUIImage,
        title: MailResourcesStrings.Localizable.emptyStateFolderTitle,
        description: MailResourcesStrings.Localizable.emptyStateFolderDescription,
        matomoName: "Folder"
    )

    static func emptyThread(from folder: Folder) -> EmptyStateView {
        let name = folder.localizedName
        return EmptyStateView(
            image: MailResourcesAsset.emptyStateThread.swiftUIImage,
            title: MailResourcesStrings.Localizable.noConversationSelected(name),
            description: "",
            matomoName: "Thread"
        )
    }

    static let noNetwork = EmptyStateView(
        image: MailResourcesAsset.emptyStateNoNetwork.swiftUIImage,
        title: MailResourcesStrings.Localizable.emptyStateNetworkTitle,
        description: MailResourcesStrings.Localizable.emptyStateNetworkDescription,
        matomoName: "Network"
    )

    static let emptySearch = EmptyStateView(
        image: UserDefaults.shared.accentColor.emptyThreadImage.swiftUIImage,
        title: MailResourcesStrings.Localizable.emptyStateSearchTitle,
        description: MailResourcesStrings.Localizable.emptyStateSearchDescription,
        withFABPadding: false,
        matomoName: "Search"
    )
}

#Preview {
    EmptyStateView.emptyFolder
}
