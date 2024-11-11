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

import DesignSystem
import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailResources
import SwiftUI

public struct DiscoveryItem {
    public let image: MailResourcesImages
    public let title: String
    public let description: String
    public let primaryButtonLabel: String
    public let matomoCategory: MatomoUtils.EventCategory
}

public extension DiscoveryItem {
    static let aiDiscovery = DiscoveryItem(
        image: MailResourcesAsset.aiIllustration,
        title: MailResourcesStrings.Localizable.aiDiscoveryTitle,
        description: MailResourcesStrings.Localizable.aiDiscoveryDescription,
        primaryButtonLabel: MailResourcesStrings.Localizable.buttonTry,
        matomoCategory: .aiWriter
    )

    static let syncDiscovery = DiscoveryItem(
        image: MailResourcesAsset.syncIllustration,
        title: MailResourcesStrings.Localizable.syncCalendarsAndContactsTitle,
        description: MailResourcesStrings.Localizable.syncCalendarsAndContactsDescription,
        primaryButtonLabel: MailResourcesStrings.Localizable.buttonStart,
        matomoCategory: .syncAutoConfig
    )

    static let updateDiscovery = DiscoveryItem(
        image: MailResourcesAsset.logoMailWithStar,
        title: MailResourcesStrings.Localizable.updateAvailableTitle,
        description: MailResourcesStrings.Localizable.updateAvailableDescription,
        primaryButtonLabel: MailResourcesStrings.Localizable.buttonUpdate,
        matomoCategory: .appUpdate
    )

    static let setAsDefaultAppDiscovery = DiscoveryItem(
        image: UserDefaults.shared.accentColor.defaultApp,
        title: MailResourcesStrings.Localizable.setAsDefaultAppTitle,
        description: MailResourcesStrings.Localizable.setAsDefaultAppDescription,
        primaryButtonLabel: MailResourcesStrings.Localizable.buttonSetNow,
        matomoCategory: .setAsDefaultApp
    )

    static let scheduleDiscovery = DiscoveryItem(
        image: MailResourcesAsset.disabledFeatureFlag,
        title: MailResourcesStrings.Localizable.disabledFeatureFlagTitle,
        description: MailResourcesStrings.Localizable.disabledFeatureFlagDescription,
        primaryButtonLabel: MailResourcesStrings.Localizable.buttonClose,
        matomoCategory: .scheduleSend
    )
}

struct DiscoveryView: View {
    @LazyInjectService private var matomo: MatomoUtils

    @Environment(\.isCompactWindow) private var isCompactWindow
    @Environment(\.dismiss) private var dismiss

    @State private var willDiscoverNewFeature = false

    let item: DiscoveryItem
    var isShowingLaterButton = true

    var onAppear: (() -> Void)?
    let completionHandler: (Bool) -> Void

    var body: some View {
        Group {
            if isCompactWindow {
                DiscoveryBottomSheetView(
                    item: item,
                    nowButton: didTouchNowButton,
                    laterButton: isShowingLaterButton ? didTouchLaterButton : nil
                )
            } else {
                DiscoveryAlertView(
                    item: item,
                    nowButton: didTouchNowButton,
                    laterButton: isShowingLaterButton ? didTouchLaterButton : nil
                )
            }
        }
        .onAppear {
            onAppear?()
        }
        .onDisappear {
            completionHandler(willDiscoverNewFeature)
            if !willDiscoverNewFeature {
                matomo.track(eventWithCategory: item.matomoCategory, name: "discoverLater")
            }
        }
    }

    private func didTouchNowButton() {
        matomo.track(eventWithCategory: item.matomoCategory, name: "discoverNow")
        willDiscoverNewFeature = true
        dismiss()
    }

    private func didTouchLaterButton() {
        dismiss()
    }
}

struct DiscoveryBottomSheetView: View {
    let item: DiscoveryItem

    let nowButton: () -> Void
    let laterButton: (() -> Void)?

    var body: some View {
        VStack(spacing: IKPadding.huge) {
            item.image.swiftUIImage

            Text(item.title)
                .multilineTextAlignment(.center)
                .textStyle(.header2)

            Text(item.description)
                .multilineTextAlignment(.center)
                .textStyle(.bodySecondary)

            VStack(spacing: IKPadding.mini) {
                Button(item.primaryButtonLabel, action: nowButton)
                    .buttonStyle(.ikBorderedProminent)

                if let laterButton {
                    Button(MailResourcesStrings.Localizable.buttonLater, action: laterButton)
                        .buttonStyle(.ikBorderless)
                }
            }
            .ikButtonFullWidth(true)
            .controlSize(.large)
        }
        .padding(.horizontal, value: .large)
        .padding(.top, value: .medium)
    }
}

struct DiscoveryAlertView: View {
    let item: DiscoveryItem

    let nowButton: () -> Void
    let laterButton: (() -> Void)?

    var body: some View {
        VStack(spacing: IKPadding.large) {
            item.image.swiftUIImage

            Text(item.title)
                .multilineTextAlignment(.center)
                .textStyle(.bodyMedium)

            Text(item.description)
                .multilineTextAlignment(.center)
                .textStyle(.bodySecondary)

            if let laterButton {
                ModalButtonsView(
                    primaryButtonTitle: item.primaryButtonLabel,
                    secondaryButtonTitle: MailResourcesStrings.Localizable.buttonLater,
                    primaryButtonAction: nowButton,
                    secondaryButtonAction: laterButton
                )
            } else {
                ModalButtonsView(
                    primaryButtonTitle: item.primaryButtonLabel,
                    primaryButtonAction: nowButton
                )
            }
        }
    }
}

#Preview {
    Group {
        DiscoveryBottomSheetView(item: .aiDiscovery, nowButton: { /* Preview */ }, laterButton: { /* Preview */ })
        DiscoveryAlertView(item: .syncDiscovery, nowButton: { /* Preview */ }, laterButton: { /* Preview */ })
        DiscoveryAlertView(item: .updateDiscovery, nowButton: { /* Preview */ }, laterButton: { /* Preview */ })
    }
}
