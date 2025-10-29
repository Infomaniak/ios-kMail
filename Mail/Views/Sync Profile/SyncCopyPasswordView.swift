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
import MailCoreUI
import MailResources
import SwiftUI

struct SyncCopyPasswordView: View {
    @EnvironmentObject private var mailboxManager: MailboxManager

    @State private var applicationPassword: String?

    @Binding var navigationPath: [SyncProfileStep]

    var body: some View {
        VStack(spacing: IKPadding.medium) {
            Text(MailResourcesStrings.Localizable.syncTutorialCopyPasswordTitle)
                .textStyle(.header2)
                .multilineTextAlignment(.center)

            VStack(spacing: IKPadding.giant) {
                MailResourcesAsset.lock.swiftUIImage

                if let applicationPassword {
                    HStack(spacing: IKPadding.medium) {
                        SecureField("", text: .constant(applicationPassword))
                            .textContentType(.password)
                            .disabled(true)
                            .padding([.vertical, .leading], value: .small)

                        Button {
                            copyPassword()
                        } label: {
                            MailResourcesAsset.duplicate
                                .iconSize(.medium)
                        }
                        .padding(.trailing, value: .medium)
                    }
                    .background {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(MailResourcesAsset.textFieldColor.swiftUIColor)
                    }
                } else {
                    ProgressView()
                }

                Text(MailResourcesStrings.Localizable.syncTutorialCopyPasswordDescription)
                    .multilineTextAlignment(.leading)
                    .textStyle(.bodySecondary)
            }
            .padding(value: .large)

            Spacer()
        }
        .padding(value: .large)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: IKPadding.mini) {
                Button(MailResourcesStrings.Localizable.buttonCopyPassword) {
                    @InjectService var matomo: MatomoUtils
                    matomo.track(eventWithCategory: .syncAutoConfig, name: "copyPassword")
                    copyPassword()
                }
                .buttonStyle(.ikBorderedProminent)
                .ikButtonFullWidth(true)
                .controlSize(.large)
                .ikButtonLoading(applicationPassword == nil)
            }
            .padding(.horizontal, value: .large)
            .padding(.bottom, IKPadding.onBoardingBottomButtons)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                SyncStepToolbarItem(step: 2, totalSteps: 3)
            }
        }
        .onAppear {
            Task {
                guard applicationPassword == nil else { return }
                await tryOrDisplayError {
                    applicationPassword = try await mailboxManager.apiFetcher.applicationPassword().password
                }
            }
        }
    }

    func copyPassword() {
        guard let applicationPassword else { return }
        UIPasteboard.general.string = applicationPassword

        @InjectService var snackbarPresenter: IKSnackBarPresentable
        snackbarPresenter.show(message: MailResourcesStrings.Localizable.snackbarPasswordCopied)
        navigationPath.append(.installProfile)
    }
}

#Preview {
    NavigationView {
        SyncCopyPasswordView(navigationPath: .constant([]))
    }
    .navigationViewStyle(.stack)
    .environmentObject(PreviewHelper.sampleMailboxManager)
}
