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

struct SenderMenuCell: View {
    @LazyInjectService private var matomo: MatomoUtils
    @LazyInjectService private var platformDetector: PlatformDetectable

    @EnvironmentObject private var draftContentManager: DraftContentManager

    @Binding var currentSignature: Signature?

    let signature: Signature

    var body: some View {
        Button {
            matomo.track(eventWithCategory: .newMessage, name: "switchIdentity")

            withAnimation {
                currentSignature = signature
            }
            draftContentManager.updateSignature(with: signature)
        } label: {
            Label {
                if platformDetector.isMac {
                    Text("\(signature.senderName) (\(signature.name)) \(signature.senderEmailIdn)")
                } else {
                    Text("\(signature.senderName) (\(signature.name))")
                }
            } icon: {
                if signature == currentSignature {
                    MailResourcesAsset.check.swiftUIImage
                }
            }
            .accessibilityHint(MailResourcesStrings.Localizable.contentDescriptionButtonSelectSignature)

            Text(signature.senderEmailIdn)
        }
    }
}

#Preview {
    SenderMenuCell(currentSignature: .constant(nil), signature: Signature())
}
