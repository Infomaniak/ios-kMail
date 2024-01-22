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

struct AttachmentView<Content: View>: View {
    private let detachedAttachment: Attachment
    private let subtitle: String

    @ViewBuilder let accessory: () -> Content?

    init(attachment: Attachment, subtitle: String, accessory: @escaping () -> Content? = { EmptyView() }) {
        detachedAttachment = attachment.detached()
        self.subtitle = subtitle
        self.accessory = accessory
    }

    var body: some View {
        HStack(spacing: UIPadding.small) {
            IKIcon(detachedAttachment.icon, size: .large)
                .foregroundStyle(MailResourcesAsset.textSecondaryColor)

            VStack(alignment: .leading, spacing: 0) {
                Text(detachedAttachment.name)
                    .textStyle(.bodySmall)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text(subtitle)
                    .textStyle(.labelSecondary)
            }

            accessory()
        }
        .frame(maxWidth: 200)
        .padding(.horizontal, value: .small)
        .padding(.vertical, value: .verySmall)
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(MailResourcesAsset.elementsColor.swiftUIColor)
        }
    }
}

#Preview {
    AttachmentView(attachment: PreviewHelper.sampleAttachment, subtitle: "24ko")
}
