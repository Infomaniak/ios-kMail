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

struct SearchBarButtonView: View {
    var body: some View {
        HStack {
            Image(resource: MailResourcesAsset.search)
                .resizable()
                .scaledToFit()
                .frame(width: Constants.searchBarIconSize, height: Constants.searchBarIconSize)

            Text(MailResourcesStrings.searchViewHint)
                .textStyle(.calloutHint)
            Spacer()

            Image(resource: MailResourcesAsset.filter)
                .resizable()
                .scaledToFit()
                .frame(width: Constants.searchBarIconSize, height: Constants.searchBarIconSize)
        }
        .padding([.top, .bottom], 10)
        .padding([.leading, .trailing], 12)
        .background(Color(MailResourcesAsset.backgroundSearchBar.color))
        .foregroundColor(MailResourcesAsset.hintTextColor)
        .cornerRadius(40)
        .padding([.leading, .trailing], 15)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 0)
    }
}

struct SearchBarButtonView_Previews: PreviewProvider {
    static var previews: some View {
        SearchBarButtonView()
    }
}
