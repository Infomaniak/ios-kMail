/*
 Infomaniak Mail - iOS App
 Copyright (C) 2025 Infomaniak Network SA

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
import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailResources
import SwiftUI

struct AttachmentsReminderView: View {
    let actionHandler: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Pièce jointe manquante ?")
                .textStyle(.bodyMedium)
                .padding(.bottom, IKPadding.alertTitleBottom)

            Text("Vous avez mentionné une pièce jointe mais aucun fichier n'a été ajouté. Envoyer quand même ?")
                .textStyle(.body)
                .padding(.bottom, IKPadding.alertDescriptionBottom)

            ModalButtonsView(primaryButtonTitle: "Envoyer") {
                @InjectService var matomo: MatomoUtils
                matomo.track(eventWithCategory: .newMessage, name: "sendWithoutSubjectConfirm")
                actionHandler()
            }
        }
    }
}

#Preview {
    AttachmentsReminderView {}
}
