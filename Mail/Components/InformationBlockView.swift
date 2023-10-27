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

extension VerticalAlignment {
    /// Alignment ID used for the icon and the text
    /// The icon must be vertically centered with the first line of the text
    enum InformationBlockAlignment: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            return context[.top]
        }
    }

    static let informationBlockAlignment = VerticalAlignment(InformationBlockAlignment.self)
}

struct InformationBlockView: View {
    let icon: Image
    let message: String
    var iconTint: Color?
    var dismissHandler: (() -> Void)?

    var body: some View {
        HStack(alignment: .informationBlockAlignment, spacing: UIPadding.intermediate) {
            icon
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundColor(iconTint)
                .alignmentGuide(.informationBlockAlignment) { d in
                    // Center of the view is on the informationBlockAlignment guide
                    d[VerticalAlignment.center]
                }

            Text(message)
                .textStyle(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .alignmentGuide(.informationBlockAlignment) { d in
                    // Center of the first line is on the informationBlockAlignment guide
                    (d.height - (d[.lastTextBaseline] - d[.firstTextBaseline])) / 2
                }

            if let dismissHandler {
                CloseButton(size: .small, dismissHandler: dismissHandler)
                    .tint(MailResourcesAsset.textSecondaryColor.swiftUIColor)
                    .alignmentGuide(.informationBlockAlignment) { d in
                        d[VerticalAlignment.center]
                    }
            }
        }
        .padding(value: .regular)
        .background(MailResourcesAsset.textFieldColor.swiftUIColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview("Without Dismiss") {
    InformationBlockView(icon: MailResourcesAsset.lightBulbShine.swiftUIImage, message: "Tip")
}

#Preview("With Dismiss") {
    InformationBlockView(icon: MailResourcesAsset.lightBulbShine.swiftUIImage, message: "Dismissible Tip") { /* Preview */ }
}
