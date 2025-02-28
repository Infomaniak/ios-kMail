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
    @LazyInjectService private var matomo: MatomoUtils

    let mailbox: Mailbox
    private let nextShowCounter = 10

    private var type: AlertType {
        guard mailbox.isFree && mailbox.isLimited, let quotas = mailbox.quotas else {
            return .none
        }

        if quotas.progression >= 1.0 {
            return .full
        } else if quotas.progression > 0.85 && nextShowQuotasAlert < appLaunchCounter.value {
            return .almostFull
        }
        return .none
    }

    var body: some View {
        if type != .none {
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

                if type == .almostFull {
                    Button {
                        nextShowQuotasAlert = appLaunchCounter.value + nextShowCounter
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
        case full
        case almostFull
        case none

        var iconColor: Color {
            switch self {
            case .full:
                return MailResourcesAsset.redColor.swiftUIColor
            default:
                return MailResourcesAsset.orangeColor.swiftUIColor
            }
        }

        var title: String {
            switch self {
            case .full:
                return MailResourcesStrings.Localizable.myKSuiteQuotasAlertFullTitle
            default:
                return MailResourcesStrings.Localizable.myKSuiteQuotasAlertTitle
            }
        }

        var description: String {
            switch self {
            case .full:
                return MailResourcesStrings.Localizable.myKSuiteQuotasAlertFullDescription
            default:
                return MailResourcesStrings.Localizable.myKSuiteQuotasAlertDescription
            }
        }
    }
}

#Preview {
    QuotasAlertView(mailbox: PreviewHelper.sampleMailbox)
}
