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

import InfomaniakCoreUI
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
}

struct DiscoveryView: View {
    @LazyInjectService private var matomo: MatomoUtils

    @Environment(\.isCompactWindow) private var isCompactWindow
    @Environment(\.dismiss) private var dismiss

    @State private var willDiscoverNewFeature = false

    let item: DiscoveryItem

    let onAppear: () -> Void
    let completionHandler: (Bool) -> Void

    var body: some View {
        Group {
            if isCompactWindow {
                DiscoveryBottomSheetView(item: item, nowButton: didTouchNowButton, laterButton: didTouchLaterButton)
            } else {
                DiscoveryAlertView(item: item, nowButton: didTouchNowButton, laterButton: didTouchLaterButton)
            }
        }
        .onAppear(perform: onAppear)
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
    let laterButton: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            item.image.swiftUIImage

            Text(item.title)
                .multilineTextAlignment(.center)
                .textStyle(.header2)

            Text(item.description)
                .multilineTextAlignment(.center)
                .textStyle(.bodySecondary)

            VStack(spacing: UIPadding.small) {
                Button(item.primaryButtonLabel, action: nowButton)
                    .ikPlainButton()

                Button(MailResourcesStrings.Localizable.buttonLater, action: laterButton)
                    .ikLinkButton()
            }
            .ikButtonFullWidth(true)
            .controlSize(.large)
        }
        .padding(.horizontal, value: .medium)
        .padding(.top, value: .regular)
    }
}

struct DiscoveryAlertView: View {
    let item: DiscoveryItem

    let nowButton: () -> Void
    let laterButton: () -> Void

    var body: some View {
        VStack(spacing: UIPadding.medium) {
            item.image.swiftUIImage

            Text(item.title)
                .multilineTextAlignment(.center)
                .textStyle(.bodyMedium)

            Text(item.description)
                .multilineTextAlignment(.center)
                .textStyle(.bodySecondary)

            ModalButtonsView(
                primaryButtonTitle: item.primaryButtonLabel,
                secondaryButtonTitle: MailResourcesStrings.Localizable.buttonLater,
                primaryButtonAction: nowButton,
                secondaryButtonAction: laterButton
            )
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
