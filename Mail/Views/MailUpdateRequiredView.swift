/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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
import VersionChecker

struct MailUpdateRequiredView: View {
    @Environment(\.openURL) private var openURL

    var dismissHandler: (() -> Void)?

    private let sharedStyle = TemplateSharedStyle(
        background: MailResourcesAsset.backgroundColor.swiftUIColor,
        titleTextStyle: .init(font: MailTextStyle.header2.font, color: MailTextStyle.header2.color),
        descriptionTextStyle: .init(font: MailTextStyle.bodySecondary.font, color: MailTextStyle.bodySecondary.color),
        buttonStyle: .init(
            background: .accentColor,
            textStyle: .init(font: MailTextStyle.bodyAccent.font, color: UserDefaults.shared.accentColor.onAccent.swiftUIColor),
            height: IKButtonHeight.large,
            radius: UIConstants.buttonsRadius
        )
    )

    var body: some View {
        UpdateRequiredView(
            image: MailResourcesAsset.updateRequired.swiftUIImage,
            sharedStyle: sharedStyle,
            updateHandler: { openURL(URLConstants.getCurrentURL().url) },
            dismissHandler: dismissHandler
        )
    }
}

#Preview {
    MailUpdateRequiredView()
}
