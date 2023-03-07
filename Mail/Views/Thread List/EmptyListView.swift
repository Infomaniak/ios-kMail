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
import MailCore
import MailResources
import SwiftUI

struct EmptyListView: View {
    @AppStorage(UserDefaults.shared.key(.accentColor)) var accentColor = DefaultPreferences.accentColor
    var isInbox: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(resource: accentColor.zeroMailImage)
            Text(isInbox ? MailResourcesStrings.Localizable.noEmailTitle : MailResourcesStrings.Localizable.emptyFolderTitle)
                .textStyle(.header2)
            Text(isInbox ? MailResourcesStrings.Localizable.noEmailDescription : MailResourcesStrings.Localizable.emptyFolderDescription)
                .textStyle(.bodySecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, Constants.floatingButtonBottomPadding + 48)
        }
        .padding(48)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .matomoView(view: [MatomoUtils.View.threadListView.displayName, "EmptyListView"])
    }
}

struct EmptyListView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyListView(isInbox: true)
    }
}
