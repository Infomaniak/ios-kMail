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

extension EdgeInsets {
    init(uiEdgeInsets insets: UIEdgeInsets) {
        self.init(top: insets.top, leading: insets.left, bottom: insets.bottom, trailing: insets.right)
    }
}

struct MoreRecipientsChip: View {
    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor

    let count: Int

    var body: some View {
        Text("+\(count)")
            .textStyle(.bodyAccent)
            .padding(EdgeInsets(uiEdgeInsets: UIPadding.recipientChip))
            .background(
                RoundedRectangle(cornerRadius: 50)
                    .fill(accentColor.secondary.swiftUIColor)
            )
    }
}

#Preview {
    MoreRecipientsChip(count: 42)
}
