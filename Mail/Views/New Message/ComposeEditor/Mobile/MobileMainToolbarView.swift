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
import InfomaniakCoreCommonUI
import InfomaniakDI
import MailCore
import MailCoreUI
import SwiftUI

struct MobileMainToolbarView: View {
    @EnvironmentObject private var mailboxManager: MailboxManager

    @Binding var isShowingClassicOptions: Bool
    @Binding var isShowingFormattingOptions: Bool
    @Binding var isShowingAI: Bool
    @Binding var isShowingKSuiteProPanel: Bool
    @Binding var isShowingMyKSuitePanel: Bool
    @Binding var isShowingMailPremiumPanel: Bool
    @Binding var isShowingEncryptStatePanel: Bool

    let draft: Draft
    let isEditorFocused: Bool

    private let leadingActions: [EditorToolbarAction] = {
        var availableOptions: [EditorToolbarAction] = [.editText, .addAttachment]

        @InjectService var featureFlagsManager: FeatureFlagsManageable
        if featureFlagsManager.isEnabled(.aiMailComposer) {
            availableOptions.append(.ai)
        }

        return availableOptions
    }()

    private let trailingActions: [EditorToolbarAction] = {
        var availableOptions: [EditorToolbarAction] = []

        @InjectService var featureFlagsManager: FeatureFlagsManageable
        if featureFlagsManager.isEnabled(.mailComposeEncrypted) {
            availableOptions.append(.encryption)
        }

        return availableOptions
    }()

    var body: some View {
        HStack(spacing: IKPadding.mini) {
            forEachActions(leadingActions)
            Spacer()
            forEachActions(trailingActions)
        }
        .padding(.horizontal, value: .medium)
    }

    private func forEachActions(_ actions: [EditorToolbarAction]) -> some View {
        ForEach(actions) { action in
            switch action {
            case .addAttachment:
                AddAttachmentMenu(draft: draft)
            case .encryption:
                EncryptionButton(isShowingEncryptStatePanel: $isShowingEncryptStatePanel, draft: draft)
                    .buttonStyle(
                        .mobileToolbar(
                            isActivated: false,
                            customTint: draft.encrypted ? EncryptionButton.encryptionEnabledForeground : nil
                        )
                    )
            case .ai:
                AIToolbarButton {
                    performToolbarAction(action)
                }
            default:
                MobileToolbarButton(toolbarAction: action, isActivated: false, customTint: action.customTint) {
                    performToolbarAction(action)
                }
                .disabled(isDisabled(action))
            }
        }
    }

    private func performToolbarAction(_ action: EditorToolbarAction) {
        if let matomoName = action.matomoName {
            @InjectService var matomo: MatomoUtils
            matomo.track(eventWithCategory: .editorActions, name: matomoName)
        }

        switch action {
        case .editText:
            withAnimation(EditorMobileToolbarView.disappearAnimation) {
                isShowingClassicOptions = false
            }
            withAnimation(EditorMobileToolbarView.appearAnimation) {
                isShowingFormattingOptions = true
            }
        case .ai:
            if mailboxManager.mailbox.pack == .kSuiteFree {
                isShowingKSuiteProPanel = true
            } else if mailboxManager.mailbox.pack == .myKSuiteFree {
                isShowingMyKSuitePanel = true
            } else if mailboxManager.mailbox.pack == .starterPack {
                isShowingMailPremiumPanel = true
            } else {
                isShowingAI = true
            }
        case .link, .bold, .underline, .italic, .strikeThrough, .cancelFormat, .unorderedList:
            break
        case .addAttachment, .addFile, .addPhoto, .takePhoto, .encryption:
            break
        }
    }

    private func isDisabled(_ action: EditorToolbarAction) -> Bool {
        if action == .editText {
            return !isEditorFocused
        } else {
            return false
        }
    }
}

#Preview {
    MobileMainToolbarView(
        isShowingClassicOptions: .constant(true),
        isShowingFormattingOptions: .constant(false),
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
