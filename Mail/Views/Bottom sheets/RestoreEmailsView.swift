/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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

import DesignSystem
import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import SwiftUI

struct RestoreEmailsView: View {
    @EnvironmentObject private var mailboxManager: MailboxManager

    @Environment(\.dismiss) private var dismiss
    @Environment(\.isCompactWindow) private var isCompactWindow

    @State private var selectedDate = ""
    @State private var availableDates = [String]()
    @State private var pickerNoSelectionText = MailResourcesStrings.Localizable.loadingText

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(MailResourcesStrings.Localizable.restoreEmailsTitle)
                .textStyle(.bodyMedium)
                .padding(.bottom, value: .medium)

            Text(MailResourcesStrings.Localizable.restoreEmailsText)
                .textStyle(.bodySecondary)
                .padding(.bottom, value: .mini)

            LargePicker(title: MailResourcesStrings.Localizable.restoreEmailsBackupDate,
                        noSelectionText: pickerNoSelectionText,
                        selection: $selectedDate,
                        items: availableDates.map(mapDates))
                .padding(.bottom, value: .large)
                .onChange(of: selectedDate) { _ in
                    @InjectService var matomo: MatomoUtils
                    matomo.track(eventWithCategory: .restoreEmailsBottomSheet, action: .input, name: "selectDate")
                }

            ModalButtonsView(
                primaryButtonTitle: MailResourcesStrings.Localizable.buttonConfirmRestoreEmails,
                secondaryButtonTitle: MailResourcesStrings.Localizable.buttonCancel,
                primaryButtonEnabled: !availableDates.isEmpty,
                primaryButtonAction: restoreEmails,
                secondaryButtonAction: dismiss.callAsFunction
            )
        }
        .padding(.horizontal, isCompactWindow ? IKPadding.bottomSheetHorizontal : 0)
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

    private func restoreEmails() async {
        @InjectService var matomo: MatomoUtils
        matomo.track(eventWithCategory: .restoreEmailsBottomSheet, name: "restore")

        await tryOrDisplayError {
            try await mailboxManager.apiFetcher.restoreBackup(mailbox: mailboxManager.mailbox, date: selectedDate)

            @InjectService var snackbarPresenter: IKSnackBarPresentable
            snackbarPresenter.show(message: MailResourcesStrings.Localizable.snackbarRestorationLaunched)
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

#Preview {
    RestoreEmailsView()
        .environmentObject(PreviewHelper.sampleMailboxManager)
}
