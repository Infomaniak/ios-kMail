/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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

import InfomaniakRichEditor
import MailCore
import MailCoreUI
import UIKit

@MainActor
final class EditorCoordinator {
    let toolbar: UIToolbar!

    private(set) var parent: EditorView
    private(set) var toolbarStyle = EditorToolbarStyle.main

    init(parent: EditorView) {
        self.parent = parent
        toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 48))
        setUpToolbar()
    }
}

// MARK: - RichEditorViewDelegate

extension EditorCoordinator: RichEditorViewDelegate {
    func richEditorViewDidLoad(_ richEditorView: RichEditorView) {
        richEditorView.html = parent.body

        let editorCSS = MessageWebViewUtils.loadCSS(for: .editor)
        for css in editorCSS {
            richEditorView.injectAdditionalCSS(css)
        }
    }

    func richEditorViewDidChange(_ richEditorView: RichEditorView) {
        parent.body = richEditorView.html
    }

    func richEditorViewDidChangeSelection(_ richEditorView: RichEditorView) {
        parent.model.cursorPosition = richEditorView.selection?.anchorPoint
    }

    func richEditorView(_ richEditorView: RichEditorView, contentHeightDidChange contentHeight: CGFloat) {
        parent.model.height = contentHeight
    }

    func richEditorView(_ richEditorView: RichEditorView, selectedTextAttributesDidChange textAttributes: RETextAttributes) {
        updateToolbarItems(for: richEditorView, style: toolbarStyle)
    }
}

// MARK: - Toolbar

extension EditorCoordinator {
    private func setUpToolbar() {
        UIConstants.applyComposeViewStyle(to: toolbar)
    }

    public func updateToolbarItems(for richEditorView: RichEditorView, style: EditorToolbarStyle) {
        toolbarStyle = style

        let flexibleSpaceItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)

        let actionItems = style.actions.map { action -> UIBarButtonItem in
            let item = UIBarButtonItem()
            item.primaryAction = UIAction(image: action.icon) { _ in
                self.onToolbarClick(item, for: richEditorView)
            }
            item.tag = action.rawValue
            item.isSelected = action.isSelected(textAttributes: richEditorView.selectedTextAttributes)

            item.tintColor = action.tint
            if action == .editText && style == .textEdition {
                item.tintColor = UserDefaults.shared.accentColor.primary.color
            }

            return item
        }
        let barButtonItems = Array(actionItems.map { [$0] }.joined(separator: [flexibleSpaceItem]))

        toolbar.setItems(barButtonItems, animated: false)
        toolbar.setNeedsLayout()
    }

    @objc private func onToolbarClick(_ sender: UIBarButtonItem, for richEditorView: RichEditorView) {
        guard let toolbarAction = EditorToolbarAction(rawValue: sender.tag) else { return }

        switch toolbarAction {
        case .ai, .addFile, .addPhoto, .takePhoto, .programMessage:
            performAppAction(toolbarAction)
        case .editText, .bold, .italic, .underline, .strikeThrough, .unorderedList, .link:
            performFormatAction(toolbarAction, for: richEditorView)
        }
    }

    private func performAppAction(_ action: EditorToolbarAction) {
        switch action {
        case .ai:
            // parent.isShowingAIPrompt = true
            break
        case .addFile:
            parent.toolbarModel.isShowingFileSelection = true
        case .addPhoto:
            parent.toolbarModel.isShowingPhotoLibrary = true
        case .takePhoto:
            parent.toolbarModel.isShowingCamera = true
        case .programMessage:
            showWorkInProgressSnackBar()
        default:
            fatalError("Action not handled")
        }
    }

    private func performFormatAction(_ action: EditorToolbarAction, for richEditorView: RichEditorView) {
        switch action {
        case .editText:
            let newToolbarStyle: EditorToolbarStyle = toolbarStyle == .main ? .textEdition : .main
            updateToolbarItems(for: richEditorView, style: newToolbarStyle)
        case .bold:
            richEditorView.bold()
        case .italic:
            richEditorView.italic()
        case .underline:
            richEditorView.underline()
        case .strikeThrough:
            richEditorView.strikethrough()
        case .unorderedList:
            richEditorView.unorderedList()
        case .link:
            parent.toolbarModel.isShowingAlert = ToolbarAlert(type: .link { text, url in
                richEditorView.addLink(url: url, text: text)
            })
        default:
            fatalError("Action not handled")
        }
    }
}
