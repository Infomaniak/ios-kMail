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
import MailCore
import MailResources
import SwiftUI

public struct InformationBlockView: View {
    let icon: Image
    let title: String?
    let message: String
    let iconColor: Color?
    let buttonAction: (() -> Void)?
    let buttonTitle: String?
    let dismissHandler: (() -> Void)?

    public init(
        icon: Image,
        title: String? = nil,
        message: String,
        iconColor: Color? = nil,
        buttonAction: (() -> Void)? = nil,
        buttonTitle: String? = nil,
        dismissHandler: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.iconColor = iconColor
        self.buttonAction = buttonAction
        self.buttonTitle = buttonTitle
        self.dismissHandler = dismissHandler
    }

    public var body: some View {
        HStack(alignment: .iconAndMultilineTextAlignment, spacing: IKPadding.intermediate) {
            icon
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundStyle(iconColor ?? .clear)
                .alignmentGuide(.iconAndMultilineTextAlignment) { d in
                    // Center of the view is on the informationBlockAlignment guide
                    d[VerticalAlignment.center]
                }

            VStack(alignment: .leading, spacing: IKPadding.intermediate) {
                VStack(alignment: .leading, spacing: IKPadding.intermediate) {
                    if let title {
                        Text(title)
                            .textStyle(.bodyMedium)
                            .multilineTextAlignment(.leading)
                    }

                    Text(message)
                        .textStyle(.body)
                        .multilineTextAlignment(.leading)
                }
                .alignmentGuide(.iconAndMultilineTextAlignment) { d in
                    // Center of the first line is on the informationBlockAlignment guide
                    (d.height - (d[.lastTextBaseline] - d[.firstTextBaseline])) / 2
                }

                if let buttonTitle, let buttonAction {
                    Button(buttonTitle, action: buttonAction)
                        .buttonStyle(.ikBorderless(isInlined: true))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let dismissHandler {
                CloseButton(size: .regular, dismissHandler: dismissHandler)
                    .tint(MailResourcesAsset.textSecondaryColor.swiftUIColor)
                    .alignmentGuide(.iconAndMultilineTextAlignment) { d in
                        d[VerticalAlignment.center]
                    }
            }
        }
        .padding(value: .medium)
        .background(MailResourcesAsset.textFieldColor.swiftUIColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview("Without Dismiss") {
    InformationBlockView(
        icon: MailResourcesAsset.lightBulbShine.swiftUIImage,
        title: "Title",
        message: "Tip",
        iconColor: .blue,
        buttonAction: {},
        buttonTitle: "Button title"
    )
}

#Preview("With Dismiss") {
    InformationBlockView(
        icon: MailResourcesAsset.lightBulbShine.swiftUIImage,
        title: "Title",
        message: "Tip",
        iconColor: .blue,
        buttonAction: {},
        buttonTitle: "Button title"
    ) {
    /* Preview */ }
}

#Preview("Without Title") {
    InformationBlockView(
        icon: MailResourcesAsset.lightBulbShine.swiftUIImage,
        message: "Tip",
        iconColor: .blue,
        buttonAction: {},
        buttonTitle: "Button title"
    )
}
