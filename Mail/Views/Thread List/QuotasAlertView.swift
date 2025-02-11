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
import InfomaniakCoreSwiftUI
import MailCore
import MailCoreUI
import MailResources
import SwiftUI

struct QuotasAlertView: View {
    let mailbox: Mailbox

    private var type: AlertType {
        guard mailbox.isFree && mailbox.isLimited, let quotas = mailbox.quotas else {
            return .none
        }

        if quotas.progression >= 1.0 {
            return .full
        } else if quotas.progression > 0.85 {
            return .notFull
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
                        .font(MailTextStyle.bodySmallMedium.font)
                        .foregroundStyle(type.titleColor)

                    Text(type.description)
                        .font(MailTextStyle.label.font)

                    Button {
                        // Free trial
                    } label: {
                        Text(MailResourcesStrings.Localizable.buttonFreeTrial)
                            .font(MailTextStyle.bodySmall.font)
                            .padding(.vertical, value: .mini)
                    }
                    .buttonStyle(.ikBorderless(isInlined: true))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if type == .notFull {
                    Button {
                        // Dismiss alert
                    } label: {
                        MailResourcesAsset.close.swiftUIImage
                            .iconSize(.medium)
                            .foregroundStyle(MailResourcesAsset.textSecondaryColor.swiftUIColor)
                    }
                }
            }
            .padding(.horizontal, value: .medium)
            .padding(.vertical, value: .mini)
            .background(type.background)
        }
    }

    enum AlertType {
        case full
        case notFull
        case none

        var background: Color {
            switch self {
            case .full:
                return MailResourcesAsset.ksuiteRedBackground.swiftUIColor
            default:
                return MailResourcesAsset.ksuiteYellowBackground.swiftUIColor
            }
        }

        var iconColor: Color {
            switch self {
            case .full:
                return MailResourcesAsset.redDarkColor.swiftUIColor
            default:
                return MailResourcesAsset.orangeDarkColor.swiftUIColor
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

        var titleColor: Color {
            switch self {
            case .full:
                return MailResourcesAsset.redUltraDarkColor.swiftUIColor
            default:
                return MailResourcesAsset.orangeUltraDarkColor.swiftUIColor
            }
        }
    }
}

#Preview {
    QuotasAlertView(mailbox: PreviewHelper.sampleMailbox)
}
