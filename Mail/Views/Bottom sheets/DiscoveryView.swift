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
    public enum DiscoveryType {
        case ai, syncCalendarsAndContacts
    }

    public let type: DiscoveryType
    public let image: MailResourcesImages
    public let title: String
    public let description: String?
    public let matomoCategory: MatomoUtils.EventCategory
}

public extension DiscoveryItem {
    static let aiDiscovery = DiscoveryItem(
        type: .ai,
        image: MailResourcesAsset.aiIllustration,
        title: MailResourcesStrings.Localizable.aiDiscoveryTitle,
        description: MailResourcesStrings.Localizable.aiDiscoveryDescription,
        matomoCategory: .aiWriter
    )

    static let syncDiscovery = DiscoveryItem(
        type: .syncCalendarsAndContacts,
        image: MailResourcesAsset.syncIllustration,
        title: MailResourcesStrings.Localizable.syncTutorialWelcomeTitle,
        description: nil,
        matomoCategory: .syncAutoConfig
    )
}

struct DiscoveryView: View {
    @LazyInjectService private var matomo: MatomoUtils

    @Environment(\.isCompactWindow) private var isCompactWindow
    @Environment(\.dismiss) private var dismiss

    let item: DiscoveryItem

    @State private var willDiscoverNewFeature = false

    let completionHandler: (Bool) -> Void

    var body: some View {
        Group {
            if isCompactWindow {
                DiscoveryBottomSheetView(item: item, tryButton: didTouchTryButton, laterButton: didTouchLaterButton)
            } else {
                DiscoveryAlertView(item: item, tryButton: didTouchTryButton, laterButton: didTouchLaterButton)
            }
        }
        .onAppear {
            if item.type == .ai {
                UserDefaults.shared.shouldPresentAIFeature = false
            }
        }
        .onDisappear {
            completionHandler(willDiscoverNewFeature)
            if !willDiscoverNewFeature {
                matomo.track(eventWithCategory: item.matomoCategory, name: "discoverLater")
            }
        }
    }

    private func didTouchTryButton() {
        matomo.track(eventWithCategory: item.matomoCategory, name: "discoverTry")
        willDiscoverNewFeature = true
        dismiss()
    }

    private func didTouchLaterButton() {
        dismiss()
    }
}

struct DiscoveryBottomSheetView: View {
    let item: DiscoveryItem

    let tryButton: () -> Void
    let laterButton: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            item.image.swiftUIImage

            Text(item.title)
                .multilineTextAlignment(.center)
                .textStyle(.header2)

            if let description = item.description {
                Text(description)
                    .multilineTextAlignment(.center)
                    .textStyle(.bodySecondary)
            }

            VStack(spacing: UIPadding.medium) {
                MailButton(
                    label: item.type == .ai ? MailResourcesStrings.Localizable.buttonTry : MailResourcesStrings.Localizable
                        .buttonStart,
                    action: tryButton
                )
                .mailButtonFullWidth(true)

                MailButton(label: MailResourcesStrings.Localizable.buttonLater, action: laterButton)
                    .mailButtonStyle(.link)
            }
        }
        .padding(.horizontal, value: .medium)
        .padding(.top, value: .regular)
    }
}

struct DiscoveryAlertView: View {
    let item: DiscoveryItem

    let tryButton: () -> Void
    let laterButton: () -> Void

    var body: some View {
        VStack(spacing: UIPadding.medium) {
            item.image.swiftUIImage

            Text(item.title)
                .multilineTextAlignment(.center)
                .textStyle(.bodyMedium)

            if let description = item.description {
                Text(description)
                    .multilineTextAlignment(.center)
                    .textStyle(.bodySecondary)
            }

            ModalButtonsView(
                primaryButtonTitle: item.type == .ai ? MailResourcesStrings.Localizable.buttonTry : MailResourcesStrings
                    .Localizable.buttonStart,
                secondaryButtonTitle: MailResourcesStrings.Localizable.buttonLater,
                primaryButtonAction: tryButton,
                secondaryButtonAction: laterButton
            )
        }
    }
}

#Preview {
    Group {
        DiscoveryBottomSheetView(item: .aiDiscovery, tryButton: { /* Preview */ }, laterButton: { /* Preview */ })
        DiscoveryAlertView(item: .aiDiscovery, tryButton: { /* Preview */ }, laterButton: { /* Preview */ })
    }
}
