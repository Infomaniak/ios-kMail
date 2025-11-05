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

import KSuiteUtils
import MailResources
import MyKSuite
import SwiftUI

public extension View {
    func mailPremiumPanel(isPresented: Binding<Bool>) -> some View {
        mailFloatingPanel(isPresented: isPresented, closeButtonHidden: true) {
            MailPremiumView()
        }
    }
}

/**
 * This offer is available In Mail only. It’s shown to users coming from a Starter Pack plan.
 * The available options are identical to those in My kSuite, so we use the same resources.
 */
public struct MailPremiumView: View {
    private let labels: [KSuiteLabel] = [
        KSuiteLabel(
            icon: MyKSuiteResources.plane.swiftUIImage,
            text: MyKSuiteLocalizable.myKSuiteUpgradeUnlimitedMailLabel
        ),
        KSuiteLabel(
            icon: MyKSuiteResources.envelope.swiftUIImage,
            text: MyKSuiteLocalizable.myKSuiteUpgradeRedirectLabel
        ),
        KSuiteLabel(
            icon: MyKSuiteResources.gift.swiftUIImage,
            text: MyKSuiteLocalizable.myKSuiteUpgradeLabel
        )
    ]

    public init() {}

    public var body: some View {
        UpSalePanelView(
            headerImage: MailResourcesAsset.upgradeMailPremium.swiftUIImage,
            title: MailResourcesStrings.Localizable.mailPremiumUpgradeTitle,
            description: MailResourcesStrings.Localizable.mailPremiumUpgradeDescription,
            labels: labels,
            additionalText: MailResourcesStrings.Localizable.mailPremiumUpgradeDetails
        )
    }
}

#Preview {
    MailPremiumView()
}
