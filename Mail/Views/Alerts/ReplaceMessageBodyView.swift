/*
 Infomaniak Mail - iOS App
 Copyright (C) 2023 Infomaniak Network SA

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

struct ReplaceMessageBodyView: View {
    @LazyInjectService private var matomo: MatomoUtils

    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(MailResourcesStrings.Localizable.aiReplacementDialogTitle)
                .textStyle(.bodyMedium)
                .padding(.bottom, IKPadding.alertTitleBottom)

            VStack(alignment: .leading, spacing: IKPadding.large) {
                Text(MailResourcesStrings.Localizable.aiReplacementDialogDescription)
            }
            .textStyle(.bodySecondary)
            .padding(.bottom, IKPadding.alertDescriptionBottom)

            ModalButtonsView(primaryButtonTitle: MailResourcesStrings.Localizable.aiReplacementDialogPositiveButton) {
                matomo.track(eventWithCategory: .aiWriter, name: "replacePropositionConfirm")
                action()
            }
        }
        .onAppear {
            matomo.track(eventWithCategory: .aiWriter, name: "replacePropositionDialog")
        }
    }
}

#Preview {
    ReplaceMessageBodyView { /* Preview */ }
}
