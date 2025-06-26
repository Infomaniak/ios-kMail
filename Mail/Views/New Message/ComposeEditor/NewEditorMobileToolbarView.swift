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

import InfomaniakCoreSwiftUI
import InfomaniakCoreUIResources
import InfomaniakRichHTMLEditor
import MailCoreUI
import MailResources
import SwiftUI

struct MobileToolbarButton: View {
    let text: String
    let icon: Image
    let action: @MainActor () -> Void

    init(toolbarAction: EditorToolbarAction, perform actionToPerform: @escaping @MainActor () -> Void) {
        text = toolbarAction.accessibilityLabel
        icon = toolbarAction.icon.swiftUIImage
        action = actionToPerform
    }

    var body: some View {
        Button(action: action) {
            Label {
                Text(text)
            } icon: {
                icon
                    .iconSize(.large)
            }
            .labelStyle(.iconOnly)
        }
    }
}

struct AddAttachmentMenu: View {
    private let action = EditorToolbarAction.addAttachment

    let completionHandler: @MainActor (EditorToolbarAction) -> Void

    var body: some View {
        Menu {
            Button {
                completionHandler(.takePhoto)
            } label: {
                Label(CoreUILocalizable.buttonUploadFromCamera, image: "")
            }
            Button {
                completionHandler(.addPhoto)
            } label: {
                Label(CoreUILocalizable.buttonUploadFromGallery, image: "")
            }
            Button {
                completionHandler(.addFile)
            } label: {
                Label(CoreUILocalizable.buttonUploadFromFiles, image: "")
            }
        } label: {
            Label {
                Text(action.accessibilityLabel)
            } icon: {
                action.icon.swiftUIImage
                    .iconSize(.large)
            }
            .labelStyle(.iconOnly)
        }
    }
}

struct NewEditorMobileToolbarView: View {
    @State private var isShowingFormattingOptions = false
    @State private var isShowingAttachmentMenu = false
    @State private var isShowingLinkAlert = false

    @ObservedObject var textAttributes: TextAttributes

    @Binding var isShowingAI: Bool

    private let mainActions: [EditorToolbarAction] = [
        .editText, .ai, .addAttachment
    ]

    private let formattingOptions: [EditorToolbarAction] = [
        .bold, .italic, .underline, .strikeThrough, .unorderedList, .link
    ]

    var body: some View {
        HStack {
            if isShowingFormattingOptions {
                HStack {
                    Button("close") {
                        isShowingFormattingOptions = false
                    }

                    ForEach(formattingOptions) { action in
                        MobileToolbarButton(toolbarAction: action) {
                            performToolbarAction(action)
                        }
                        .mailCustomAlert(isPresented: $isShowingLinkAlert) {
                            AddLinkView(actionHandler: didCreateLink)
                        }
                    }
                }
            } else {
                HStack {
                    ForEach(mainActions) { action in
                        switch action {
                        case .addAttachment:
                            AddAttachmentMenu(completionHandler: performToolbarAction)
                                .tint(Color(action.tint))
                        default:
                            MobileToolbarButton(toolbarAction: action) {
                                performToolbarAction(action)
                            }
                            .tint(Color(action.tint))
                        }
                    }
                }
            }
        }
        .animation(.default, value: isShowingFormattingOptions)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding()
        .background(MailResourcesAsset.backgroundColor.swiftUIColor)
    }

    private func performToolbarAction(_ action: EditorToolbarAction) {
        switch action {
        case .editText:
            isShowingFormattingOptions = true
        case .addAttachment:
            isShowingAttachmentMenu = true
        case .ai:
            isShowingAI = true
        case .link, .bold, .underline, .italic, .strikeThrough, .cancelFormat, .unorderedList:
            formatText(for: action)
        case .addFile, .addPhoto, .takePhoto:
            break
        }
    }

    private func formatText(for action: EditorToolbarAction) {
        switch action {
        case .bold:
            textAttributes.bold()
        case .underline:
            textAttributes.underline()
        case .italic:
            textAttributes.italic()
        case .strikeThrough:
            textAttributes.strikethrough()
        case .cancelFormat:
            textAttributes.removeFormat()
        case .unorderedList:
            textAttributes.unorderedList()
        case .link:
            if textAttributes.hasLink {
                textAttributes.unlink()
            } else {
                isShowingLinkAlert = true
            }
        default:
            return
        }
    }

    private func didCreateLink(url: URL, text: String) {
        textAttributes.addLink(url: url, text: text)
    }
}

#Preview {
    NewEditorMobileToolbarView(
        textAttributes: TextAttributes(),
        isShowingAI: .constant(false)
    )
}
