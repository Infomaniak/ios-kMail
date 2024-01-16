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

import Foundation
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailResources
import SwiftUI

struct EmptySubjectView: View {
    @LazyInjectService private var matomo: MatomoUtils

    let actionHandler: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(MailResourcesStrings.Localizable.emailWithoutSubjectTitle)
                .textStyle(.bodyMedium)
                .padding(.bottom, UIPadding.alertTitleBottom)

            Text(MailResourcesStrings.Localizable.emailWithoutSubjectDescription)
                .textStyle(.body)
                .padding(.bottom, UIPadding.alertDescriptionBottom)

            ModalButtonsView(primaryButtonTitle: MailResourcesStrings.Localizable.buttonContinue) {
                matomo.track(eventWithCategory: .newMessage, name: "sendWithoutSubjectConfirm")
                actionHandler()
            }
        }
    }
}

#Preview {
    EmptySubjectView { /* Preview */ }
}
