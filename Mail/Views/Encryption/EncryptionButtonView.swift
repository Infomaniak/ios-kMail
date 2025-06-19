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

import MailCore
import MailResources
import SwiftUI

struct EncryptionButtonView: View {
    let draft: Draft
    let didTap: () -> Void

    private var count: String? {
        guard draft.encrypted else { return nil }
        guard !draft.autoEncryptDisable.isEmpty else { return nil }

        if draft.autoEncryptDisable.count <= 9 {
            return String(draft.autoEncryptDisable.count)
        }
        return "+9"
    }

    var body: some View {
        Button {
            didTap()
        } label: {
            draft.encrypted ?
                MailResourcesAsset.lockSquare.swiftUIImage : MailResourcesAsset.unlockSquare.swiftUIImage
        }
        .foregroundColor(draft.encrypted ? Color.accentColor : MailResourcesAsset.textSecondaryColor.swiftUIColor)
        .overlay {
            if let count {
                Circle()
                    .fill(MailResourcesAsset.orangeColor.swiftUIColor)
                    .overlay {
                        Text(count)
                            .font(.system(size: 8))
                            .foregroundStyle(MailResourcesAsset.backgroundTertiaryColor.swiftUIColor)
                    }
                    .frame(width: 14)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .offset(x: 7)
            }
        }
    }
}

#Preview {
    EncryptionButtonView(draft: Draft()) {}
}
