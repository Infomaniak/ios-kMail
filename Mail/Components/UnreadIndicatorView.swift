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
import SwiftUI

struct UnreadIndicatorView: View {
    var hidden = false

    var body: some View {
        Circle()
            .frame(width: UIConstants.unreadIconSize, height: UIConstants.unreadIconSize)
            .foregroundStyle(hidden ? .clear : .accentColor)
    }
}

struct UnreadIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        UnreadIndicatorView(hidden: false)
    }
}
