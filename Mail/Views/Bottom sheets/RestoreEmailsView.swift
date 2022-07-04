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

import InfomaniakCore
import MailCore
import MailResources
import SwiftUI

struct RestoreEmailsView: View {
    @State private var selectedDate = ""
    @State private var availableDates = [String]()

    let state: GlobalBottomSheet
    let mailboxManager: MailboxManager

    var body: some View {
        VStack(alignment: .leading) {
            Text(MailResourcesStrings.Localizable.restoreEmailsTitle)
                .textStyle(.header3)
                .padding(.bottom, 16)

            Text(MailResourcesStrings.Localizable.restoreEmailsText)
                .textStyle(.body)
                .padding(.bottom, 10)

            LargePicker(title: MailResourcesStrings.Localizable.restoreEmailsBackupDate,
                        selection: $selectedDate,
                        items: availableDates.map(mapDates))
            .padding(.bottom, 24)

            HStack(spacing: 24) {
                Button(action: cancel) {
                    Text(MailResourcesStrings.Localizable.buttonCancel)
                }

                Button(action: restoreEmails) {
                    Text(MailResourcesStrings.Localizable.buttonConfirmRestoreEmails)
                        .foregroundColor(.white)
                        .textStyle(.button)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 18)
                        .background(Color.accentColor)
                        .cornerRadius(16)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, Constants.bottomSheetHorizontalPadding)
        .task {
            await tryOrDisplayError {
                availableDates = try await mailboxManager.apiFetcher.listBackups(mailbox: mailboxManager.mailbox).backups
                selectedDate = availableDates.last ?? ""
            }
        }
    }

    private func cancel() {
        state.close()
    }

    private func restoreEmails() {
        Task {
            await tryOrDisplayError {
                try await mailboxManager.apiFetcher.restoreBackup(mailbox: mailboxManager.mailbox, date: selectedDate)
                await IKSnackBar.showSnackBar(message: MailResourcesStrings.Localizable.snackbarSuccessfulRestoration)
            }
        }
        state.close()
    }

    private func mapDates(_ date: String) -> LargePicker<String>.Item<String> {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        let formattedDate = dateFormatter.date(from: date)

        let label = formattedDate?.formatted(date: .long, time: .shortened)

        return .init(id: date, name: label ?? date)
    }
}

struct RestoreEmailsView_Previews: PreviewProvider {
    static var previews: some View {
        RestoreEmailsView(state: GlobalBottomSheet(), mailboxManager: PreviewHelper.sampleMailboxManager)
    }
}
