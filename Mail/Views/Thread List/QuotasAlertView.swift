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

import DesignSystem
import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import SwiftUI

struct QuotasAlertView: View {
    @AppStorage(UserDefaults.shared.key(.nextShowQuotasAlert)) private var nextShowQuotasAlert = 0
    @InjectService private var appLaunchCounter: AppLaunchCounter

    let mailbox: Mailbox
    private let nextShowCounter = 10

    private var type: AlertType? {
        guard let pack = mailbox.pack,
              pack == .myKSuiteFree || pack == .kSuiteFree,
              let quotas = mailbox.quotas else {
            return nil
        }

        if quotas.progression >= 1.0 {
            return .full(isPro: pack == .myKSuitePlus || pack == .kSuitePaid)
        } else if quotas.progression > 0.85 && nextShowQuotasAlert < appLaunchCounter.value {
            return .almostFull(isPro: pack == .myKSuitePlus || pack == .kSuitePaid)
        }
        return nil
    }

    var body: some View {
        if let type {
            HStack(alignment: .top, spacing: IKPadding.small) {
                MailResourcesAsset.warningFill.swiftUIImage
                    .iconSize(.medium)
                    .foregroundStyle(type.iconColor)

                VStack(alignment: .leading, spacing: IKPadding.micro) {
                    Text(type.title)
                        .textStyle(.bodySmallMedium)

                    Text(type.description)
                        .textStyle(.label)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if case .almostFull = type {
                    Button {
                        nextShowQuotasAlert = appLaunchCounter.value + nextShowCounter
                        @InjectService var matomo: MatomoUtils
                        matomo.track(eventWithCategory: .myKSuite, name: "closeStorageWarningBanner")
                    } label: {
                        MailResourcesAsset.close.swiftUIImage
                            .iconSize(.medium)
                            .foregroundStyle(MailResourcesAsset.textSecondaryColor.swiftUIColor)
                    }
                }
            }
            .padding(.horizontal, value: .medium)
            .padding(.vertical, value: .mini)
            .background(MailResourcesAsset.hoverMenuBackground.swiftUIColor)
        }
    }

    enum AlertType {
        case full(isPro: Bool)
        case almostFull(isPro: Bool)

        var iconColor: Color {
            switch self {
            case .full:
                return MailResourcesAsset.redColor.swiftUIColor
            case .almostFull:
                return MailResourcesAsset.orangeColor.swiftUIColor
            }
        }

        var title: String {
            switch self {
            case .full(let pro):
                return pro ? MailResourcesStrings.Localizable.kSuiteProQuotasAlertFullTitle : MailResourcesStrings.Localizable
                    .myKSuiteQuotasAlertFullTitle
            case .almostFull:
                return MailResourcesStrings.Localizable.myKSuiteQuotasAlertTitle
            }
        }

        var description: String {
            switch self {
            case .full(let pro):
                return pro ?
                    MailResourcesStrings.Localizable.kSuiteProQuotasAlertFullDescription :
                    MailResourcesStrings.Localizable.myKSuiteQuotasAlertFullDescription
            case .almostFull(let pro):
                return pro ?
                    MailResourcesStrings.Localizable.kSuiteProQuotasAlertDescription :
                    MailResourcesStrings.Localizable.myKSuiteQuotasAlertDescription
            }
        }
    }
}

#Preview {
    QuotasAlertView(mailbox: PreviewHelper.sampleMailbox)
}
