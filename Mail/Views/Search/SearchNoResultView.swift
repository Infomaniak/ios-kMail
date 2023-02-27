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

import MailResources
import SwiftUI

struct SearchNoResultView: View {
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Image(resource: MailResourcesAsset.search)
                .resizable()
                .frame(width: 74, height: 74)
                .padding(.bottom, 13)
                .foregroundColor(MailResourcesAsset.textSecondaryColor)
            Text(MailResourcesStrings.Localizable.searchNoResultsTitle)
                .textStyle(.header2)
            Text(MailResourcesStrings.Localizable.searchNoResultsDescription)
                .textStyle(.bodySecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .listRowSeparator(.hidden)
    }
}

struct SearchNoResultView_Previews: PreviewProvider {
    static var previews: some View {
        SearchNoResultView()
    }
}
