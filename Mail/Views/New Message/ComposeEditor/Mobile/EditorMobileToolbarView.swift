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
import InfomaniakCoreSwiftUI
import InfomaniakCoreUIResources
import InfomaniakRichHTMLEditor
import MailCore
import MailCoreUI
import MailResources
import PhotosUI
import SwiftModalPresentation
import SwiftUI

struct EditorMobileToolbarView: View {
    private static let baseAnimation = Animation.default.speed(2)
    static let appearAnimation = Self.baseAnimation.delay(0.05)
    static let disappearAnimation = Self.baseAnimation

    static let colorPrimary = MailResourcesAsset.textSecondaryColor.swiftUIColor
    static let colorSecondary = MailResourcesAsset.backgroundColor.swiftUIColor

    @State private var isShowingClassicOptions = true
    @State private var isShowingFormattingOptions = false

    @ObservedObject var textAttributes: TextAttributes

    @Binding var isShowingAI: Bool
    @Binding var isShowingKSuiteProPanel: Bool
    @Binding var isShowingMyKSuitePanel: Bool
    @Binding var isShowingMailPremiumPanel: Bool
    @Binding var isShowingEncryptStatePanel: Bool

    let draft: Draft
    let isEditorFocused: Bool

    private let transition = AnyTransition.opacity.combined(with: .move(edge: .bottom))

    var body: some View {
        ZStack {
            if isShowingClassicOptions {
                MobileMainToolbarView(
                    isShowingClassicOptions: $isShowingClassicOptions,
                    isShowingFormattingOptions: $isShowingFormattingOptions,
                    isShowingAI: $isShowingAI,
                    isShowingKSuiteProPanel: $isShowingKSuiteProPanel,
                    isShowingMyKSuitePanel: $isShowingMyKSuitePanel,
                    isShowingMailPremiumPanel: $isShowingMailPremiumPanel,
                    isShowingEncryptStatePanel: $isShowingEncryptStatePanel,
                    draft: draft,
                    isEditorFocused: isEditorFocused
                )
                .transition(transition)
            }

            if isShowingFormattingOptions {
                MobileFormattingToolbarView(
                    textAttributes: textAttributes,
                    isShowingClassicOptions: $isShowingClassicOptions,
                    isShowingFormattingOptions: $isShowingFormattingOptions
                )
                .transition(transition)
            }
        }
        .frame(minHeight: MobileToolbarButtonStyle.iconSize.rawValue + MobileToolbarButtonStyle.verticalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Self.colorSecondary)
        .overlay(alignment: .top) {
            Divider()
                .frame(height: 1)
                .overlay(Color(uiColor: .systemGray3))
        }
    }
}

#Preview {
    EditorMobileToolbarView(
        textAttributes: TextAttributes(),
        isShowingAI: .constant(false),
        isShowingKSuiteProPanel: .constant(false),
        isShowingMyKSuitePanel: .constant(false),
        isShowingMailPremiumPanel: .constant(false),
        isShowingEncryptStatePanel: .constant(false),
        draft: Draft(),
        isEditorFocused: true
    )
    .environmentObject(AttachmentsManager(
        draftLocalUUID: "",
        mailboxManager: PreviewHelper.sampleMailboxManager
    ))
}
