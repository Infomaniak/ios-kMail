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
            if let mailEditor = editor as? MailEditor {
                mailEditor.getToolbar(height: 44, style: mailEditor.toolbarStyle)
            }
            editor.getHTML { html in
                if let html = html, self.parent.body.trimmingCharacters(in: .whitespacesAndNewlines) != html {
                    self.parent.body = html
                }
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

    public func getToolbar(height: Int, style: ToolbarStyle) -> UIToolbar? {
        toolbar.frame = CGRect(x: 0, y: 50, width: 320, height: height)
        toolbar.tintColor = MailResourcesAsset.secondaryTextColor.color
        toolbar.barTintColor = .white

        let editTextButton = UIBarButtonItem(
            image: MailResourcesAsset.textModes.image,
            style: .plain,
            target: self,
            action: style == .textEdition
                ? #selector(onToolbarBackClick(sender:))
                : #selector(onToolbarTextEditionClick(sender:))
        )
        editTextButton.tintColor = style == .textEdition
            ? MailResourcesAsset.infomaniakColor.color
            : MailResourcesAsset.secondaryTextColor.color

        let attachmentButton = UIBarButtonItem(
            image: MailResourcesAsset.attachmentMail2.image,
            style: .plain,
            target: self,
            action: #selector(onToolbarBackClick(sender:))
        )
        let photoButton = UIBarButtonItem(
            image: MailResourcesAsset.photo.image,
            style: .plain,
            target: self,
            action: #selector(onToolbarBackClick(sender:))
        )
        let linkButton = UIBarButtonItem(
            image: MailResourcesAsset.hyperlink.image,
            style: .plain,
            target: self,
            action: #selector(onToolbarLinkClick(sender:))
        )
        let programMessageButton = UIBarButtonItem(
            image: MailResourcesAsset.programMessage.image,
            style: .plain,
            target: self,
            action: #selector(onToolbarBackClick(sender:))
        )

        let boldTextButton = UIBarButtonItem(
            title: "Bold",
            style: .plain,
            target: self,
            action: #selector(onToolbarTextEditionClick(sender:))
        )
        boldTextButton.tag = TextEditionAction.bold.rawValue
        boldTextButton.isSelected = selectedTextAttribute.format.hasBold

        let italicTextButton = UIBarButtonItem(
            image: MailResourcesAsset.italic.image,
            style: .plain,
            target: self,
            action: #selector(onToolbarTextEditionClick(sender:))
        )
        italicTextButton.tag = TextEditionAction.italic.rawValue
        italicTextButton.isSelected = selectedTextAttribute.format.hasItalic

        let underlineTextButton = UIBarButtonItem(
            image: MailResourcesAsset.underline.image,
            style: .plain,
            target: self,
            action: #selector(onToolbarTextEditionClick(sender:))
        )
        underlineTextButton.tag = TextEditionAction.underline.rawValue
        underlineTextButton.isSelected = selectedTextAttribute.format.hasUnderline

        let strikeThroughTextButton = UIBarButtonItem(
            image: MailResourcesAsset.strikeThrough.image,
            style: .plain,
            target: self,
            action: #selector(onToolbarTextEditionClick(sender:))
        )
        strikeThroughTextButton.tag = TextEditionAction.strikeThrough.rawValue
        strikeThroughTextButton.isSelected = selectedTextAttribute.format.hasStrikethrough

        let unorderedListTextButton = UIBarButtonItem(
            image: MailResourcesAsset.unorderedList.image,
            style: .plain,
            target: self,
            action: #selector(onToolbarTextEditionClick(sender:))
        )
        unorderedListTextButton.tag = TextEditionAction.unorderedList.rawValue

        let flexibleSpaceItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)

        switch style {
        case .main:
            toolbar.setItems(
                [
                    editTextButton,
                    flexibleSpaceItem,
                    attachmentButton,
                    flexibleSpaceItem,
                    photoButton,
                    flexibleSpaceItem,
                    linkButton,
                    flexibleSpaceItem,
                    programMessageButton
                ],
                animated: false
            )
        case .textEdition:
            toolbar.setItems(
                [
                    editTextButton,
                    flexibleSpaceItem,
                    boldTextButton,
                    flexibleSpaceItem,
                    italicTextButton,
                    flexibleSpaceItem,
                    underlineTextButton,
                    flexibleSpaceItem,
                    strikeThroughTextButton,
                    flexibleSpaceItem,
                    unorderedListTextButton
                ],
                animated: false
            )
        }
        toolbar.isUserInteractionEnabled = true

        toolbar.sizeToFit()
        return toolbar
    }

    @objc func onToolbarTextEditionClick(sender: UIBarButtonItem) {
        switch sender.tag {
        case TextEditionAction.bold.rawValue:
            sender.isSelected.toggle()
            bold()
        case TextEditionAction.italic.rawValue:
            sender.isSelected.toggle()
            italic()
        case TextEditionAction.underline.rawValue:
            sender.isSelected.toggle()
            underline()
        case TextEditionAction.strikeThrough.rawValue:
            sender.isSelected.toggle()
            strikethrough()
        case TextEditionAction.unorderedList.rawValue:
            makeUnorderedList()
        default:
            toolbarStyle = .textEdition
            webView.addInputAccessoryView(toolbar: getToolbar(height: 44, style: toolbarStyle))
            toolbar.setNeedsLayout()
        }
    }

    @objc func onToolbarLinkClick(sender: UIBarButtonItem) {
        webView.resignFirstResponder()
        bottomSheet?.open(state: .link, position: .top)
        bottomSheet?.actionHandler = { url in
            self.makeLink(url: url)
            self.bottomSheet?.close()
        }
    }

    @objc func onToolbarBackClick(sender: UIBarButtonItem) {
        toolbarStyle = .main
        webView.addInputAccessoryView(toolbar: getToolbar(height: 44, style: toolbarStyle))
        toolbar.setNeedsLayout()
    }
}

enum ToolbarStyle {
    case main
    case textEdition
}

enum TextEditionAction: Int {
    case bold = 1
    case italic
    case underline
    case strikeThrough
    case unorderedList
}
