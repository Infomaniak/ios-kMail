/*
 Infomaniak Mail - iOS App
 Copyright (C) 2025 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import MailCore
import MailCoreUI
import MailResources
import SwiftUI

struct ComposeMessageDateHeaderView: View {
    @Binding var isShowingSendOptionsPanel: Bool

    let icon: Image
    let message: String
    let onCancel: () -> Void

    var body: some View {
        MessageHeaderActionView(
            icon: icon,
            message: message,
            showTopSeparator: false,
            showBottomSeparator: true,
            shouldDisplayActions: true
        ) {
            HStack {
                Button(MailResourcesStrings.Localizable.buttonReschedule) {
                    isShowingSendOptionsPanel = true
                }
                MessageHeaderDivider()
                Button(MailResourcesStrings.Localizable.buttonCancel, action: onCancel)
            }
        }
    }
}

#Preview {
    ComposeMessageDateHeaderView(
        isShowingSendOptionsPanel: .constant(false),
        icon: MailResourcesAsset.alarmClock.swiftUIImage,
        message: MailResourcesStrings.Localizable.callIfNoResponseHeaderTitle("Tomorrow at 10:00")
    ) {}
}
