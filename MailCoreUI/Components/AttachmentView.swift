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

import InfomaniakCoreSwiftUI
import MailCore
import MailResources
import SwiftUI

public struct AttachmentView<Content: View>: View {
    private let title: String
    private let subtitle: String
    private let icon: MailResourcesImages

    @ViewBuilder let accessory: () -> Content?

    let downloadProgress: Double

    private var isDownloading: Bool {
        return downloadProgress > 0 && downloadProgress < 1
    }

    public init(
        title: String,
        subtitle: String,
        icon: MailResourcesImages,
        downloadProgress: Double = 0,
        accessory: @escaping () -> Content? = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.downloadProgress = downloadProgress
        self.accessory = accessory
    }

    public init(
        attachment: Attachment,
        downloadProgress: Double = 0,
        accessory: @escaping () -> Content? = { EmptyView() }
    ) {
        title = attachment.name
        subtitle = attachment.size.formatted(.defaultByteCount)
        icon = attachment.icon
        self.downloadProgress = downloadProgress
        self.accessory = accessory
    }

    public init(
        swissTransferFile: File,
        downloadProgress: Double = 0,
        accessory: @escaping () -> Content? = { EmptyView() }
    ) {
        title = swissTransferFile.name
        subtitle = swissTransferFile.size.formatted(.defaultByteCount)
        icon = swissTransferFile.icon
        self.downloadProgress = downloadProgress
        self.accessory = accessory
    }

    public var body: some View {
        HStack(spacing: IKPadding.small) {
            if isDownloading {
                ProgressView(value: downloadProgress)
                    .progressViewStyle(MailCircularProgressViewStyle())
            } else {
                icon
                    .iconSize(.large)
                    .foregroundStyle(MailResourcesAsset.textSecondaryColor)
            }

            VStack(alignment: .leading, spacing: 0) {
                Text(title)
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
        .padding(.vertical, value: .extraSmall)
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(MailResourcesAsset.elementsColor.swiftUIColor)
        }
    }
}

#Preview {
    AttachmentView(title: "title", subtitle: "24ko", icon: PreviewHelper.sampleAttachment.icon)
}
