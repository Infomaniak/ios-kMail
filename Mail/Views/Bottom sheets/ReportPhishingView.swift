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

struct ReportPhishingView: View {
    let mailboxManager: MailboxManager
    @ObservedObject var state: GlobalBottomSheet
    let message: Message

    var body: some View {
        VStack(spacing: 16) {
            Text(MailResourcesStrings.Localizable.reportPhishingTitle)
                .textStyle(.header3)
                .frame(maxWidth: .infinity, alignment: .leading)
            Image(resource: MailResourcesAsset.phishing)
            Text(MailResourcesStrings.Localizable.reportPhishingDescription)
            .textStyle(.bodySecondary)
            BottomSheetButtonsView(primaryButtonTitle: MailResourcesStrings.Localizable.buttonReport,
                                   secondaryButtonTitle: MailResourcesStrings.Localizable.buttonCancel,
                                   primaryButtonAction: report) {
                state.close()
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, Constants.bottomSheetHorizontalPadding)
    }

    private func report() {
        state.close()
        Task {
            await tryOrDisplayError {
                let response = try await mailboxManager.apiFetcher.reportPhishing(message: message)
                if response {
                    _ = try await mailboxManager.reportSpam(messages: [message.freezeIfNeeded()])
                    IKSnackBar.showSnackBar(message: MailResourcesStrings.Localizable.snackbarReportPhishingConfirmation)
                }
            }
        }
    }
}

struct PhishingView_Previews: PreviewProvider {
    static var previews: some View {
        ReportPhishingView(mailboxManager: PreviewHelper.sampleMailboxManager,
                           state: GlobalBottomSheet(),
                           message: PreviewHelper.sampleMessage)
    }
}
