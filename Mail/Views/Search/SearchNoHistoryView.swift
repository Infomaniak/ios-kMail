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

struct SearchNoHistoryView: View {
    var body: some View {
        Text(MailResourcesStrings.Localizable.emptyStateHistoryDescription)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, 16)
            .textStyle(.bodySmallSecondary)
            .listRowSeparator(.hidden)
            .listRowBackground(MailResourcesAsset.backgroundColor.swiftUIColor)
            .listRowInsets(.init(top: 0, leading: 12, bottom: 0, trailing: 12))
    }
}

struct SearchNoHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        SearchNoHistoryView()
    }
}
