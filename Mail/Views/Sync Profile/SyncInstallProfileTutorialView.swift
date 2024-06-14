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

import InfomaniakCore
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import SwiftUI

extension MailResourcesImages: Identifiable {
    public var id: String {
        name
    }
}

struct SyncInstallProfileTutorialView: View {
    @LazyInjectService private var matomo: MatomoUtils

    @Environment(\.dismissModal) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var userCameBackFromSettings = false

    private let steps = [
        MailResourcesStrings.Localizable.syncTutorialInstallProfileStep1,
        MailResourcesStrings.Localizable.syncTutorialInstallProfileStep2,
        MailResourcesStrings.Localizable.syncTutorialInstallProfileStep3,
        MailResourcesStrings.Localizable.syncTutorialInstallProfileStep4,
        MailResourcesStrings.Localizable.syncTutorialInstallProfileStep5
    ]

    let tutorialStepImages = [
        MailResourcesAsset.syncTutorial1,
        MailResourcesAsset.syncTutorial2,
        MailResourcesAsset.syncTutorial3,
        MailResourcesAsset.syncTutorial4,
        MailResourcesAsset.syncTutorial5
    ]

    init() {
        UIPageControl.appearance().currentPageIndicatorTintColor = .tintColor
        UIPageControl.appearance().pageIndicatorTintColor = MailResourcesAsset.elementsColor.color
    }

    var body: some View {
        ScrollView {
            VStack {
                VStack(spacing: UIPadding.regular) {
                    Text(MailResourcesStrings.Localizable.syncTutorialInstallProfileTitle)
                        .textStyle(.header2)
                        .multilineTextAlignment(.center)
                    VStack(alignment: .leading, spacing: UIPadding.regular) {
                        ForEach(steps.indices, id: \.self) { index in
                            if let stepMarkdown = try? AttributedString(markdown: "\(index + 1)\\. \(steps[index])") {
                                Text(stepMarkdown)
                            }
                            if index == 0 {
                                InformationBlockView(
                                    icon: MailResourcesAsset.lightBulbShine.swiftUIImage,
                                    message: MailResourcesStrings.Localizable.syncTutorialInstallProfileTip,
                                    iconColor: .accentColor
                                )
                            }
                        }
                    }
                    .textStyle(.bodySecondary)
                }
                .padding(value: .medium)

                TabView {
                    ForEach(tutorialStepImages) { step in
                        step.swiftUIImage
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: UIConstants.buttonsRadius))
                            .padding(.bottom, value: .large)
                    }
                }
                .tabViewStyle(.page)
                .frame(height: 256 + UIPadding.large)
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                SyncStepToolbarItem(step: 3, totalSteps: 3)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: UIPadding.small) {
                Button(MailResourcesStrings.Localizable.buttonGoToSettings) {
                    matomo.track(eventWithCategory: .syncAutoConfig, name: "openSettings")
                    @InjectService var platformDetector: PlatformDetectable
                    let url: URL
                    if platformDetector.isMac {
                        url = DeeplinkConstants.macSecurityAndPrivacy
                    } else {
                        url = DeeplinkConstants.iosPreferences
                    }
                    openURL(url)
                }
                .buttonStyle(.ikPlain)

                if userCameBackFromSettings {
                    Button(MailResourcesStrings.Localizable.buttonImDone) {
                        matomo.track(eventWithCategory: .syncAutoConfig, name: "done")
                        dismiss()
                    }
                    .buttonStyle(.ikLink())
                }
            }
            .controlSize(.large)
            .ikButtonFullWidth(true)
            .padding(.top, value: .verySmall)
            .padding(.horizontal, value: .medium)
            .background(MailResourcesAsset.backgroundColor.swiftUIColor)
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                withAnimation {
                    userCameBackFromSettings = true
                }
            }
        }
        .onAppear {
            UserDefaults.shared.shouldPresentSyncDiscovery = false
        }
    }
}

#Preview {
    NavigationView {
        SyncInstallProfileTutorialView()
    }
    .navigationViewStyle(.stack)
}
