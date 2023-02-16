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

struct FlushFolderAlertView: View {
    @Binding var isPresented: Bool

    var deletedMessages: Int?
    let confirmHandler: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(MailResourcesStrings.Localizable.threadListFlushFolderAlertTitle(10))
                .textStyle(.bodyMedium)

            Text(MailResourcesStrings.Localizable.threadListFlushFolderAlertDescription)
                .textStyle(.body)

            BottomSheetButtonsView(primaryButtonTitle: MailResourcesStrings.Localizable.buttonConfirm,
                                   secondaryButtonTitle: MailResourcesStrings.Localizable.buttonClose) {
                confirmHandler()
                isPresented = false
            } secondaryButtonAction: {
                isPresented = false
            }

        }
    }
}

struct FlushFolderAlertView_Previews: PreviewProvider {
    static var previews: some View {
        FlushFolderAlertView(isPresented: .constant(true)) { /* Preview */ }
    }
}
