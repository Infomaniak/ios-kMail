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
import Sentry
import SwiftUI

struct ReportDisplayProblemView: View {
    @EnvironmentObject private var mailboxManager: MailboxManager
    let message: Message

    var body: some View {
        VStack(spacing: 16) {
            Text(MailResourcesStrings.Localizable.reportDisplayProblemTitle)
                .textStyle(.bodyMedium)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(MailResourcesStrings.Localizable.reportDisplayProblemDescription)
                .textStyle(.bodySecondary)
            ModalButtonsView(primaryButtonTitle: MailResourcesStrings.Localizable.buttonAccept,
                             secondaryButtonTitle: MailResourcesStrings.Localizable.buttonRefuse,
                             primaryButtonAction: report)
                .padding(.top, 8)
        }
        .matomoView(view: [MatomoUtils.View.bottomSheet.displayName, "ReportDisplayProblemView"])
    }

    private func report() async {
        await tryOrDisplayError {
            // Download message
            let fileURL = try await mailboxManager.apiFetcher.download(messages: [message])
            guard let firstFileURL = fileURL.first else { throw MailError.unknownError }
            // Send it via Sentry
            let fileAttachment = Attachment(path: firstFileURL.path,
                                            filename: firstFileURL.lastPathComponent,
                                            contentType: "message/rfc822")
            _ = SentrySDK.capture(message: "Message display problem reported") { scope in
                scope.addAttachment(fileAttachment)
            }

            @InjectService var snackbarPresenter: IKSnackBarPresentable
            snackbarPresenter.show(message: MailResourcesStrings.Localizable.snackbarDisplayProblemReported)
        }
    }
}

#Preview {
    ReportDisplayProblemView(message: PreviewHelper.sampleMessage)
        .environmentObject(PreviewHelper.sampleMailboxManager)
}
