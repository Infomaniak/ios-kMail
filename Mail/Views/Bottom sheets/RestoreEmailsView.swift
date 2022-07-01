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

struct RestoreEmailsView: View {
    private var availableDates = [""]

    @State private var selectedDate = ""

    var body: some View {
        VStack {
            Text(MailResourcesStrings.Localizable.restoreEmailsTitle)
                .textStyle(.header3)

            Text(MailResourcesStrings.Localizable.restoreEmailsText)
                .textStyle(.body)

            LargePicker(title: MailResourcesStrings.Localizable.restoreEmailsBackupDate,
                        selection: $selectedDate,
                        items: availableDates.map { _ in .init(id: "", name: "Hello") })

            HStack(spacing: 24) {
                Button(action: cancel) {
                    Text(MailResourcesStrings.Localizable.buttonCancel)
                }

                Button(action: restoreEmails) {
                    Text(MailResourcesStrings.Localizable.buttonConfirmRestoreEmails)
                }
            }
        }
        .padding(.horizontal, Constants.bottomSheetHorizontalPadding)
    }

    // MARK: - Actions

    private func cancel() {

    }

    private func restoreEmails() {

    }
}

struct RestoreEmailsView_Previews: PreviewProvider {
    static var previews: some View {
        RestoreEmailsView()
    }
}
