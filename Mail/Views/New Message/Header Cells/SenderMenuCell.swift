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

import MailCore
import MailResources
import SwiftUI

struct SenderMenuCell: View {
    @EnvironmentObject private var draftContentManager: DraftContentManager

    @Binding var currentSignature: Signature?

    let signature: Signature

    var body: some View {
        Button {
            withAnimation {
                self.currentSignature = signature
            }
            draftContentManager.updateSignature(with: signature)
        } label: {
            Label {
                Text("\(signature.senderName) (\(signature.name))")
            } icon: {
                if signature == currentSignature {
                    MailResourcesAsset.check.swiftUIImage
                }
            }

            Text(signature.senderEmailIdn)
        }
    }
}

struct SenderMenuCell_Previews: PreviewProvider {
    static var previews: some View {
        SenderMenuCell(currentSignature: .constant(nil), signature: Signature())
    }
}
