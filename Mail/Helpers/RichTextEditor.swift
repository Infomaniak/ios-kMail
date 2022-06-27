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

import MailCore
import MailResources
import SQRichTextEditor
import SwiftUI
import WebKit

struct RichTextEditor: UIViewRepresentable {
    typealias UIViewType = UIView

    @Binding var model: RichTextEditorModel
    @Binding var body: String

    var richTextEditor: SQTextEditorView {
        return model.richTextEditor
    }

    class Coordinator: SQTextEditorDelegate {
        var parent: RichTextEditor

        init(_ parent: RichTextEditor) {
            self.parent = parent // tell the coordinator what its parent is, so it can modify values there directly
        }

        func editorDidLoad(_ editor: SQTextEditorView) {
            parent.model.richTextEditor.insertHTML(parent.body) { error in
                if let error = error {
                    print("Failed to load editor: \(error)")
                }
            }
            parent.model.richTextEditor.moveCursorToStart()
        }

        func editor(_ editor: SQTextEditorView, cursorPositionDidChange position: SQEditorCursorPosition) {
            parent.model.delegateCount += 1
            guard parent.model.isInitialized else { return }
            editor.getHTML { html in
                if let html = html, self.parent.body.trimmingCharacters(in: .whitespacesAndNewlines) != html {
                    self.parent.body = html
                }
            }
        }

        func editor(_ editor: SQTextEditorView, selectedTextAttributeDidChange attribute: SQTextAttribute) {
            if let mailEditor = editor as? MailEditor {
                mailEditor.setToolbar(style: mailEditor.toolbarStyle)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    func makeUIView(context: Context) -> UIView {
        richTextEditor.delegate = context.coordinator
        return richTextEditor
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Intentionally unimplemented...
    }
}

class RichTextEditorModel: ObservableObject {
    let richTextEditor: MailEditor
    @Published var delegateCount = 0
    var isInitialized: Bool {
        delegateCount > 2
    }

    init() {
        richTextEditor = MailEditor()
    }
}

class MailEditor: SQTextEditorView {
    var toolbar = UIToolbar()
    var bottomSheet: NewMessageBottomSheet?
    var toolbarStyle = ToolbarStyle.main

    private lazy var editorWebView: WKWebView = {
        let config = WKWebViewConfiguration()
        config.preferences = WKPreferences()
        config.preferences.minimumFontSize = 10
        config.preferences.javaScriptCanOpenWindowsAutomatically = false
        config.processPool = WKProcessPool()
        config.userContentController = WKUserContentController()
        config.setURLSchemeHandler(URLSchemeHandler(), forURLScheme: URLSchemeHandler.scheme)

        JSMessageName.allCases.forEach {
            config.userContentController.add(self, name: $0.rawValue)
        }

        // inject css to html
        if customCss == nil,
           let cssURL = Bundle(for: SQTextEditorView.self).url(forResource: "editor", withExtension: "css"),
           let css = try? String(contentsOf: cssURL, encoding: .utf8) {
            customCss = css
        }

        if let css = customCss {
            let cssStyle = """
                javascript:(function() {
                var parent = document.getElementsByTagName('head').item(0);
                var style = document.createElement('style');
                style.type = 'text/css';
                style.innerHTML = window.atob('\(encodeStringTo64(fromString: css))');
                parent.appendChild(style)})()
            """
            let cssScript = WKUserScript(source: cssStyle, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
            config.userContentController.addUserScript(cssScript)
        }

        let _webView = WKWebView(frame: .zero, configuration: config)
        _webView.translatesAutoresizingMaskIntoConstraints = false
        _webView.navigationDelegate = self
        _webView.allowsLinkPreview = false
        _webView.setKeyboardRequiresUserInteraction(false)
        _webView.addInputAccessoryView(toolbar: self.getToolbar(height: 44, style: .main))
        return _webView
    }()

    override var webView: WKWebView {
        get {
            return editorWebView
        }
        set {
            editorWebView = newValue
        }
    }

    private func callEditorMethod(name: String, completion: ((_ error: Error?) -> Void)?) {
        webView.evaluateJavaScript("editor.\(name)()") { _, error in
            completion?(error)
        }
    }

    // MARK: - Editor methods

    /// Removes any current selection and moves the cursor to the very beginning of the document.
    func moveCursorToStart(completion: ((_ error: Error?) -> Void)? = nil) {
        callEditorMethod(name: "moveCursorToStart", completion: completion)
    }

    /// Removes any current selection and moves the cursor to the very end of the document.
    func moveCursorToEnd(completion: ((_ error: Error?) -> Void)? = nil) {
        callEditorMethod(name: "moveCursorToEnd", completion: completion)
    }

    func addBold(completion: ((_ error: Error?) -> Void)? = nil) {
        callEditorMethod(name: "bold", completion: completion)
    }

    func makeUnorderedList(completion: ((_ error: Error?) -> Void)? = nil) {
        callEditorMethod(name: "makeUnorderedList", completion: completion)
    }

    func removeList(completion: ((_ error: Error?) -> Void)? = nil) {
        callEditorMethod(name: "removeList", completion: completion)
    }

    // MARK: - Custom Toolbar

    public func setToolbar(style: ToolbarStyle) {
        toolbarStyle = style
        webView.addInputAccessoryView(toolbar: getToolbar(height: 44, style: toolbarStyle))
    }

    public func getToolbar(height: Int, style: ToolbarStyle) -> UIToolbar? {
        toolbar.frame = CGRect(x: 0, y: 50, width: 320, height: height)
        toolbar.tintColor = MailResourcesAsset.secondaryTextColor.color
        toolbar.barTintColor = .white

        let flexibleSpaceItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)

        let actionItems = style.actions.map { action -> UIBarButtonItem in
            let item = UIBarButtonItem(
                image: action.icon,
                style: .plain,
                target: self,
                action: #selector(onToolbarClick(sender:))
            )
            item.tag = action.rawValue
            item.isSelected = action.isSelected(textAttribute: selectedTextAttribute)
            if action == .editText && style == .textEdition {
                item.tintColor = MailResourcesAsset.infomaniakColor.color
            }
            return item
        }
        let barButtonItems = Array(actionItems.map { [$0] }.joined(separator: [flexibleSpaceItem]))

        toolbar.setItems(barButtonItems, animated: false)
        toolbar.isUserInteractionEnabled = true
        toolbar.sizeToFit()

        return toolbar
    }

    @objc func onToolbarClick(sender: UIBarButtonItem) {
        switch ToolbarAction(rawValue: sender.tag) {
        case .bold:
            bold()
        case .italic:
            italic()
        case .underline:
            underline()
        case .strikeThrough:
            strikethrough()
        case .unorderedList:
            makeUnorderedList()
        case .editText:
            setToolbar(style: toolbarStyle == .main ? .textEdition : .main)
            toolbar.setNeedsLayout()
        case .attachment:
            // TODO: Handle Attachment
            break
        case .photo:
            // TODO: Handle photo
            break
        case .link:
            if selectedTextAttribute.format.hasLink {
                removeLink()
            } else {
                webView.resignFirstResponder()
                bottomSheet?.open(state: .link { url in
                    self.makeLink(url: url)
                    self.bottomSheet?.close()
                }, position: .top)
            }
        case .programMessage:
            // TODO: Handle programmed message
            break
        case .none:
            return
        }
    }
}

enum ToolbarStyle {
    case main
    case textEdition

    var actions: [ToolbarAction] {
        switch self {
        case .main:
            return [.editText, .attachment, .photo, .link, .programMessage]
        case .textEdition:
            return [.editText, .bold, .italic, .underline, .strikeThrough, .unorderedList]
        }
    }
}

enum ToolbarAction: Int {
    case bold = 1
    case italic
    case underline
    case strikeThrough
    case unorderedList
    case editText
    case attachment
    case photo
    case link
    case programMessage

    var icon: UIImage {
        switch self {
        case .bold:
            return MailResourcesAsset.bold.image
        case .italic:
            return MailResourcesAsset.italic.image
        case .underline:
            return MailResourcesAsset.underline.image
        case .strikeThrough:
            return MailResourcesAsset.strikeThrough.image
        case .unorderedList:
            return MailResourcesAsset.unorderedList.image
        case .editText:
            return MailResourcesAsset.textModes.image
        case .attachment:
            return MailResourcesAsset.attachmentMail2.image
        case .photo:
            return MailResourcesAsset.photo.image
        case .link:
            return MailResourcesAsset.hyperlink.image
        case .programMessage:
            return MailResourcesAsset.programMessage.image
        }
    }

    func isSelected(textAttribute: SQTextAttribute) -> Bool {
        switch self {
        case .bold:
            return textAttribute.format.hasBold
        case .italic:
            return textAttribute.format.hasItalic
        case .underline:
            return textAttribute.format.hasUnderline
        case .strikeThrough:
            return textAttribute.format.hasStrikethrough
        case .link:
            return textAttribute.format.hasLink
        case .unorderedList, .editText, .attachment, .photo, .programMessage:
            return false
        }
    }
}
