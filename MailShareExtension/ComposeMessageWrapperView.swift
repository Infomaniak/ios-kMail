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

import InfomaniakCore
import InfomaniakCoreSwiftUI
import InfomaniakDI
import InfomaniakOnboarding
import Lottie
import MailCore
import MailCoreUI
import MailResources
import MobileCoreServices
import Social
import SwiftUI
import UIKit
import UniformTypeIdentifiers
import VersionChecker

struct ComposeMessageWrapperView: View {
    @LazyInjectService private var accountManager: AccountManager
    @LazyInjectService private var featureFlagsManager: FeatureFlagsManageable

    @State private var versionStatus: VersionStatus?

    let itemProviders: [NSItemProvider]
    let dismissHandler: SimpleClosure

    static let typePropertyList = UTType.propertyList.identifier

    /// All the Attachments that should directly provide URLs and title for a new Email Draft
    var htmlAttachments: [HTMLAttachable] {
        // All property list, result from JS execution in Safari, wrapped in a type that can format HTML
        let propertyListItems: [HTMLAttachable] = itemProviders
            .filter { $0.hasItemConformingToTypeIdentifier(Self.typePropertyList) }
            .map { SafariKeyValueToHTMLAttachment(wrapping: $0) }

        // All `.webloc` item providers, wrapped in a type that can read it on the fly
        let weblocTextAttachments = itemProviders
            .filter { $0.underlyingType == .isURL }
            .compactMap { WeblocToTextAttachment(wrapping: $0) }

        // All `.txt` item providers, wrapped in a type that can read it on the fly
        let txtTextAttachments = itemProviders
            .filter { $0.underlyingType == .isText }
            .compactMap { TxtToTextAttachment(wrapping: $0) }

        let allItems: [HTMLAttachable] = propertyListItems + weblocTextAttachments + txtTextAttachments
        return allItems
    }

    /// All the Attachments that should be uploaded as standalone files for a new Email Draft
    var attachments: [Attachable] {
        itemProviders.filter { itemProvider in
            let isPropertyList = itemProvider.hasItemConformingToTypeIdentifier(Self.typePropertyList)
            let isUrlAsWebloc = itemProvider.underlyingType == .isURL
            let isTextAsTxt = itemProvider.underlyingType == .isText

            return !isPropertyList && !isUrlAsWebloc && !isTextAsTxt
        }
    }

    var body: some View {
        Group {
            if versionStatus == .updateIsRequired {
                MailUpdateRequiredView { dismissHandler(()) }
            } else if let mailboxManager = accountManager.currentMailboxManager {
                ComposeMessageIntentView(
                    composeMessageIntent: .new(fromExtension: true),
                    htmlAttachments: htmlAttachments,
                    attachments: attachments
                )
                .environmentObject(mailboxManager)
                .environment(\.dismissModal) {
                    dismissHandler(())
                }
                .task {
                    try? await featureFlagsManager.fetchFlags()
                }
            } else {
                PleaseLoginView(tapHandler: dismissHandler)
            }
        }
        .task {
            try? await checkAppVersion()
        }
    }

    @MainActor private func checkAppVersion() async throws {
        versionStatus = try? await VersionChecker.standard.checkAppVersionStatus()
    }
}

extension Slide {
    static var pleaseLogin =
        Slide(
            backgroundImage: MailResourcesAsset.onboardingBackground1.image,
            backgroundImageTintColor: UserDefaults.shared.accentColor.secondary.color,
            content: .animation(IKLottieConfiguration(
                id: 1,
                filename: "illu_onboarding_1",
                bundle: MailResourcesResources.bundle,
                loopFrameStart: 54,
                loopFrameEnd: 138,
                lottieConfiguration: .init(renderingEngine: .mainThread)
            )),
            bottomView: OnboardingTextView(
                title: MailResourcesStrings.Localizable.pleaseLogInFirst,
                description: ""
            )
        )
}

struct PleaseLoginView: View {
    var tapHandler: SimpleClosure

    var body: some View {
        WaveView(slides: [Slide.pleaseLogin], selectedSlide: .constant(0)) { _ in
            Button(MailResourcesStrings.Localizable.buttonClose) {
                tapHandler(())
            }
            .buttonStyle(.ikBorderedProminent)
            .ikButtonFullWidth(true)
            .controlSize(.large)
            .padding(.horizontal, value: .large)
            .padding(.bottom, IKPadding.onBoardingBottomButtons)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    PleaseLoginView {}
}
