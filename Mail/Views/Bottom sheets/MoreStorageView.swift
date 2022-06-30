//
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

import MailCore
import MailResources
import SwiftUI

struct MoreStorageView: View {
    var body: some View {
        VStack(alignment: .leading) {
            Image(resource: MailResourcesAsset.moreStorage)

            Text(MailResourcesStrings.Localizable.getMoreStorageTitle)
                .textStyle(.header3)

            Text(MailResourcesStrings.Localizable.getMoreStorageText)
                .textStyle(.body)
        }
        .padding([.leading, .trailing], Constants.bottomSheetVerticalPadding)
    }
}

struct MoreStorageView_Previews: PreviewProvider {
    static var previews: some View {
        MoreStorageView()
            .previewLayout(.sizeThatFits)
    }
}
