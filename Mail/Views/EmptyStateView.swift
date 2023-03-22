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

    let matomoName: String

    var body: some View {
        VStack(spacing: 8) {
            image

            Text(title)
                .textStyle(.header2)
            Text(description)
                .textStyle(.bodySecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 48)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .matomoView(view: [MatomoUtils.View.threadListView.displayName, "EmptyListView"])
    }
}

extension EmptyStateView {
    static let emptyFolder = EmptyStateView(
        image: <#T##Image#>,
        title: <#T##String#>,
        description: <#T##String#>,
        matomoName: <#T##String#>
    )
}

struct EmptyListView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyStateView(isInbox: true)
    }
}
