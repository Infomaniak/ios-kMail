/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

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
import InfomaniakConcurrency
import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import SwiftUI

struct ReportPhishingView: View {
    @EnvironmentObject private var mailboxManager: MailboxManager
    let messagesWithDuplicates: [Message]

    let distinctMessageCount: Int

    var completionHandler: ((Action) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(MailResourcesStrings.Localizable.reportPhishingTitle)
                .textStyle(.bodyMedium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, IKPadding.alertTitleBottom)
            Text(MailResourcesStrings.Localizable.reportPhishingDescription(distinctMessageCount))
                .textStyle(.bodySecondary)
                .padding(.bottom, IKPadding.alertDescriptionBottom)
            ModalButtonsView(primaryButtonTitle: MailResourcesStrings.Localizable.buttonConfirm, primaryButtonAction: report)
        }
    }

    private func report() async {
        await tryOrDisplayError {
            let latestResponses = try await messagesWithDuplicates.concurrentMap { message in
                try await mailboxManager.apiFetcher.reportPhishing(message: message)
            }

            @InjectService var snackbarPresenter: IKSnackBarPresentable
            if latestResponses.allSatisfy({ $0 == true }) {
                let messagesFreeze = messagesWithDuplicates.map { $0.freezeIfNeeded() }
                _ = try await mailboxManager.move(messages: messagesFreeze, to: .spam)
                snackbarPresenter.show(message: MailResourcesStrings.Localizable.snackbarReportPhishingConfirmation)
            } else {
                snackbarPresenter.show(message: MailResourcesStrings.Localizable.snackbarReportPhishingError)
            }
        }

        guard let completionHandler else { return }
        completionHandler(.spam)
    }
}

#Preview {
    ReportPhishingView(messagesWithDuplicates: PreviewHelper.sampleMessages, distinctMessageCount: 1)
        .environmentObject(PreviewHelper.sampleMailboxManager)
}
