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
import MailResources
import SwiftUI

public extension DiscoveryItem {
    static let aiDiscovery = DiscoveryItem(
        content: .lottie(name: "discoveryIllustrationEuria", bundle: MailResourcesResources.bundle),
        title: MailResourcesStrings.Localizable.aiDiscoveryTitle,
        description: MailResourcesStrings.Localizable.aiDiscoveryDescription,
        primaryButtonLabel: MailResourcesStrings.Localizable.buttonTry,
        shouldDisplayLaterButton: true
    )

    static let syncDiscovery = DiscoveryItem(
        content: .image(MailResourcesAsset.syncIllustration.swiftUIImage),
        title: MailResourcesStrings.Localizable.syncCalendarsAndContactsTitle,
        description: MailResourcesStrings.Localizable.syncCalendarsAndContactsDescription,
        primaryButtonLabel: MailResourcesStrings.Localizable.buttonStart,
        shouldDisplayLaterButton: true
    )

    static let updateDiscovery = DiscoveryItem(
        content: .image(MailResourcesAsset.logoMailWithStar.swiftUIImage),
        title: MailResourcesStrings.Localizable.updateAvailableTitle,
        description: MailResourcesStrings.Localizable.updateAvailableDescription,
        primaryButtonLabel: MailResourcesStrings.Localizable.buttonUpdate,
        shouldDisplayLaterButton: true
    )

    static let setAsDefaultAppDiscovery = DiscoveryItem(
        content: .image(UserDefaults.shared.accentColor.defaultApp.swiftUIImage),
        title: MailResourcesStrings.Localizable.setAsDefaultAppTitle,
        description: MailResourcesStrings.Localizable.setAsDefaultAppDescription,
        primaryButtonLabel: MailResourcesStrings.Localizable.buttonSetNow,
        shouldDisplayLaterButton: true
    )

    static let scheduleDiscovery = DiscoveryItem(
        content: .image(MailResourcesAsset.updateRequired.swiftUIImage),
        title: MailResourcesStrings.Localizable.disabledFeatureFlagTitle,
        description: MailResourcesStrings.Localizable.disabledFeatureFlagDescription,
        primaryButtonLabel: MailResourcesStrings.Localizable.buttonClose,
        shouldDisplayLaterButton: false
    )
}
