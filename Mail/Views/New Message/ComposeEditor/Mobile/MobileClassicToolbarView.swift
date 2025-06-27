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

struct MobileClassicToolbarView: View {
    @Binding var isShowingClassicOptions: Bool
    @Binding var isShowingFormattingOptions: Bool
    @Binding var isShowingAI: Bool

    let draft: Draft
    let isEditorFocused: Bool

    private let actions: [EditorToolbarAction] = {
        var availableOptions: [EditorToolbarAction] = [.editText, .addAttachment]

        @InjectService var featureFlagsManager: FeatureFlagsManageable
        if featureFlagsManager.isEnabled(.aiMailComposer) {
            availableOptions.append(.ai)
        }

        return availableOptions
    }()

    var body: some View {
        HStack(spacing: 0) {
            ForEach(actions) { action in
                switch action {
                case .addAttachment:
                    AddAttachmentMenu(draft: draft)
                        .tint(action.tint)
                default:
                    MobileToolbarButton(toolbarAction: action) {
                        performToolbarAction(action)
                    }
                    .tint(action.tint)
                    .disabled(isDisabled(action))
                }
            }
        }
        .padding(.horizontal, value: .medium)
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
            isShowingAI = true
        case .link, .bold, .underline, .italic, .strikeThrough, .cancelFormat, .unorderedList:
            break
        case .addAttachment, .addFile, .addPhoto, .takePhoto:
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
    MobileClassicToolbarView(
        isShowingClassicOptions: .constant(true),
        isShowingFormattingOptions: .constant(false),
        isShowingAI: .constant(false),
        draft: Draft(),
        isEditorFocused: true
    )
    .environmentObject(AttachmentsManager(
        draftLocalUUID: "",
        mailboxManager: PreviewHelper.sampleMailboxManager
    ))
}
