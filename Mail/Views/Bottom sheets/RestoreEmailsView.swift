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
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailResources
import SwiftUI

struct RestoreEmailsView: View {
    @State private var selectedDate = ""
    @State private var availableDates = [String]()

    @State private var pickerNoSelectionText = MailResourcesStrings.Localizable.loadingText

    @LazyInjectService private var matomo: MatomoUtils

    let mailboxManager: MailboxManager

    var body: some View {
        VStack(alignment: .leading) {
            Text(MailResourcesStrings.Localizable.restoreEmailsTitle)
                .textStyle(.bodyMedium)
                .padding(.bottom, 16)

            Text(MailResourcesStrings.Localizable.restoreEmailsText)
                .textStyle(.bodySecondary)
                .padding(.bottom, 10)

            LargePicker(title: MailResourcesStrings.Localizable.restoreEmailsBackupDate,
                        noSelectionText: pickerNoSelectionText,
                        selection: $selectedDate,
                        items: availableDates.map(mapDates))
                .padding(.bottom, 24)
                .onChange(of: selectedDate) { _ in
                    matomo.track(eventWithCategory: .restoreEmailsBottomSheet, action: .input, name: "selectDate")
                }

            ModalButtonsView(primaryButtonTitle: MailResourcesStrings.Localizable.buttonConfirmRestoreEmails,
                             secondaryButtonTitle: nil,
                             primaryButtonEnabled: !availableDates.isEmpty,
                             primaryButtonAction: restoreEmails)
        }
        .padding(.horizontal, Constants.bottomSheetHorizontalPadding)
        .task {
            await tryOrDisplayError {
                let backupsList = try await mailboxManager.apiFetcher.listBackups(mailbox: mailboxManager.mailbox).backups
                withAnimation {
                    availableDates = backupsList
                    selectedDate = backupsList.last ?? ""
                    pickerNoSelectionText = MailResourcesStrings.Localizable.pickerNoSelection
                }
            }
        }
        .matomoView(view: [MatomoUtils.View.bottomSheet.displayName, "RestoreEmailsView"])
    }

    private func restoreEmails() {
        matomo.track(eventWithCategory: .restoreEmailsBottomSheet, name: "restore")
        Task {
            await tryOrDisplayError {
                try await mailboxManager.apiFetcher.restoreBackup(mailbox: mailboxManager.mailbox, date: selectedDate)
                await IKSnackBar.showSnackBar(message: MailResourcesStrings.Localizable.snackbarSuccessfulRestoration)
            }
        }
    }

    private func mapDates(_ backupDate: String) -> LargePicker<String, EmptyView>.Item<String> {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        let date = dateFormatter.date(from: backupDate)

        let formattedDate = date?.formatted(date: .long, time: .shortened)

        return .init(id: backupDate, name: formattedDate ?? backupDate)
    }
}

struct RestoreEmailsView_Previews: PreviewProvider {
    static var previews: some View {
        RestoreEmailsView(mailboxManager: PreviewHelper.sampleMailboxManager)
    }
}
