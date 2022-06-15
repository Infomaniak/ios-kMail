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

struct NoNetworkView: View {
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(resource: MailResourcesAsset.noSignal)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                    Text(MailResourcesStrings.noNetworkTitle)
                        .font(MailTextStyle.calloutStrong.font)
                }
                .foregroundColor(MailResourcesAsset.warningColor)
                Text(MailResourcesStrings.noNetworkDescription)
                    .textStyle(.calloutSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            SeparatorView(withPadding: false, fullWidth: true)
        }
    }
}

struct NoNetworkView_Previews: PreviewProvider {
    static var previews: some View {
        NoNetworkView()
    }
}
