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
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import SwiftUI

struct ReportPhishingView: View {
    @LazyInjectService private var snackbarPresenter: SnackBarPresentable
    @EnvironmentObject private var mailboxManager: MailboxManager
    let messagesWithDuplicates: [Message]

    let distinctMessageCount: Int

    var completionHandler: ((Action) -> Void)?

    var reportPhishingDescription: String {
        if distinctMessageCount <= 1 {
            return MailResourcesStrings.Localizable.reportPhishingDescription
        } else {
            return MailResourcesStrings.Localizable.reportPhishingDescriptionPlural
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(MailResourcesStrings.Localizable.reportPhishingTitle)
                .textStyle(.bodyMedium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, IKPadding.alertTitleBottom)
            Text(reportPhishingDescription)
                .textStyle(.bodySecondary)
                .padding(.bottom, IKPadding.alertDescriptionBottom)
            ModalButtonsView(primaryButtonTitle: MailResourcesStrings.Localizable.buttonConfirm, primaryButtonAction: report)
        }
    }

    private func report() async {
        await tryOrDisplayError {
            var lastResponse = false
            for message in messagesWithDuplicates {
                lastResponse = try await mailboxManager.apiFetcher.reportPhishing(message: message)
            }

            if lastResponse {
                let messagesFreeze = messagesWithDuplicates.map { $0.freezeIfNeeded() }
                _ = try await mailboxManager.move(messages: messagesFreeze, to: .spam)
                snackbarPresenter.show(message: MailResourcesStrings.Localizable.snackbarReportPhishingConfirmation)
            }
        }

        guard let completionHandler = completionHandler else { return }
        completionHandler(.spam)
    }
}

#Preview {
    ReportPhishingView(messagesWithDuplicates: PreviewHelper.sampleMessages, distinctMessageCount: 1)
        .environmentObject(PreviewHelper.sampleMailboxManager)
}
