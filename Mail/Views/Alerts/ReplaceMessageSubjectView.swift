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

import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailResources
import SwiftUI

struct ReplaceMessageSubjectView: View {
    @LazyInjectService private var matomo: MatomoUtils

    let subject: String
    let action: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(MailResourcesStrings.Localizable.aiReplaceSubjectTitle)
                .textStyle(.bodyMedium)
                .padding(.bottom, UIPadding.alertTitleBottom)

            Text(MailResourcesStrings.Localizable.aiReplaceSubjectDescription(subject))
                .textStyle(.bodySecondary)
                .padding(.bottom, UIPadding.alertDescriptionBottom)

            ModalButtonsView(
                primaryButtonTitle: MailResourcesStrings.Localizable.aiReplacementDialogPositiveButton,
                secondaryButtonTitle: MailResourcesStrings.Localizable.buttonNo
            ) {
                matomo.track(eventWithCategory: .aiWriter, name: "replaceSubjectConfirm")
                action(true)
            } secondaryButtonAction: {
                matomo.track(eventWithCategory: .aiWriter, name: "keepSubject")
                action(false)
            }
        }
        .onAppear {
            matomo.track(eventWithCategory: .aiWriter, name: "replaceSubjectDialog")
        }
    }
}

#Preview {
    ReplaceMessageSubjectView(subject: "My Subject") { _ in /* Preview */ }
}
