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
    typealias UIViewType = MailEditorView

    @Binding var model: RichTextEditorModel
    @Binding var body: String
    @Binding var isShowingCamera: Bool
    @Binding var isShowingFileSelection: Bool
    @Binding var isShowingPhotoLibrary: Bool
    var alert: ObservedObject<NewMessageAlert>.Wrapper

    private var isFirstTime = true
    private var delegateCount = 0
    private var isInitialized: Bool {
        delegateCount > 2
    }

    init(model: Binding<RichTextEditorModel>, body: Binding<String>,
         alert: ObservedObject<NewMessageAlert>.Wrapper,
         isShowingCamera: Binding<Bool>, isShowingFileSelection: Binding<Bool>, isShowingPhotoLibrary: Binding<Bool>) {
        _model = model
        _body = body
        self.alert = alert
        _isShowingCamera = isShowingCamera
        _isShowingFileSelection = isShowingFileSelection
        _isShowingPhotoLibrary = isShowingPhotoLibrary
    }

    class Coordinator: SQTextEditorDelegate {
        var parent: RichTextEditor

        init(_ parent: RichTextEditor) {
            self.parent = parent // tell the coordinator what its parent is, so it can modify values there directly
        }

        func editorDidLoad(_ editor: SQTextEditorView) {
            editor.insertHTML(parent.body) { error in
                if let error = error {
                    print("Failed to load editor: \(error)")
                }
            }
            (editor as? MailEditorView)?.moveCursorToStart()
            editor.webView.scrollView.isScrollEnabled = false
            parent.model.height = CGFloat(editor.contentHeight)
        }

        func editor(_ editor: SQTextEditorView, contentHeightDidChange height: Int) {
            parent.model.height = CGFloat(height)
        }

        func editor(_ editor: SQTextEditorView, cursorPositionDidChange position: SQEditorCursorPosition) {
            parent.delegateCount += 1
            guard parent.isInitialized else { return }
            let newCursorPosition = CGFloat(position.bottom) + 20
            if parent.model.cursorPosition != newCursorPosition {
                parent.model.cursorPosition = newCursorPosition
            }
        }

        func editor(_ editor: SQTextEditorView, selectedTextAttributeDidChange attribute: SQTextAttribute) {
            if let mailEditor = editor as? MailEditorView {
                mailEditor.updateToolbarItems(style: mailEditor.toolbarStyle)
            }
        }

        func editorContentChanged(_ editor: SQTextEditorView, content: String) {
            var parentBody = parent.body.trimmingCharacters(in: .whitespacesAndNewlines)
            parentBody = parentBody.replacingOccurrences(of: "\r", with: "")
            if parentBody != content && !parent.isFirstTime {
                parent.body = content
            }
            parent.isFirstTime = false
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    func makeUIView(context: Context) -> MailEditorView {
        let richTextEditor = MailEditorView(alert: alert,
                                            isShowingCamera: $isShowingCamera,
                                            isShowingFileSelection: $isShowingFileSelection,
                                            isShowingPhotoLibrary: $isShowingPhotoLibrary)
        richTextEditor.delegate = context.coordinator
        return richTextEditor
    }

    func updateUIView(_ uiView: MailEditorView, context: Context) {
        // Intentionally unimplemented...
    }

    static func dismantleUIView(_ uiView: MailEditorView, coordinator: Coordinator) {
        uiView.webView.configuration.userContentController.removeAllScriptMessageHandlers()
    }
}

struct RichTextEditorModel {
    var cursorPosition: CGFloat = 0
    var height: CGFloat = 0
}

class MailEditorView: SQTextEditorView {
    lazy var toolbar = getToolbar()
    var alert: ObservedObject<NewMessageAlert>.Wrapper
    var isShowingCamera: Binding<Bool>
    var isShowingFileSelection: Binding<Bool>
    var isShowingPhotoLibrary: Binding<Bool>

    var toolbarStyle = ToolbarStyle.main

    init(alert: ObservedObject<NewMessageAlert>.Wrapper,
         isShowingCamera: Binding<Bool>, isShowingFileSelection: Binding<Bool>, isShowingPhotoLibrary: Binding<Bool>) {
        self.alert = alert
        self.isShowingCamera = isShowingCamera
        self.isShowingFileSelection = isShowingFileSelection
        self.isShowingPhotoLibrary = isShowingPhotoLibrary
        super.init()
    }

    private lazy var editorWebView: WKWebView = {
        let config = WKWebViewConfiguration()
        config.preferences = WKPreferences()
        config.preferences.minimumFontSize = 10
        config.preferences.javaScriptCanOpenWindowsAutomatically = false
        config.processPool = WKProcessPool()
        config.userContentController = WKUserContentController()
        config.setURLSchemeHandler(URLSchemeHandler(), forURLScheme: URLSchemeHandler.scheme)

        for jsMessageName in JSMessageName.allCases {
            config.userContentController.add(self, name: jsMessageName.rawValue)
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
        _webView.addInputAccessoryView(toolbar: self.toolbar)
        self.updateToolbarItems(style: .main)
        _webView.scrollView.keyboardDismissMode = .interactive
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

    public func updateToolbarItems(style: ToolbarStyle) {
        toolbarStyle = style

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
                item.tintColor = UserDefaults.shared.accentColor.primary.color
            }
            return item
        }
        let barButtonItems = Array(actionItems.map { [$0] }.joined(separator: [flexibleSpaceItem]))

        toolbar.setItems(barButtonItems, animated: false)
        toolbar.setNeedsLayout()
    }

    public func getToolbar() -> UIToolbar {
        let newToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 55))
        newToolbar.tintColor = MailResourcesAsset.toolbarEditorTextColor.color
        newToolbar.barTintColor = MailResourcesAsset.backgroundToolbarEditorColor.color
        newToolbar.isTranslucent = false

        // Shadow
        newToolbar.setShadowImage(UIImage(), forToolbarPosition: .any)
        newToolbar.layer.shadowColor = UIColor.black.cgColor
        newToolbar.layer.shadowOpacity = 0.1
        newToolbar.layer.shadowOffset = CGSize(width: 1, height: 1)
        newToolbar.layer.shadowRadius = 2
        newToolbar.layer.masksToBounds = false

        return newToolbar
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
            updateToolbarItems(style: toolbarStyle == .main ? .textEdition : .main)
        case .addFile:
            isShowingFileSelection.wrappedValue.toggle()
        case .addPhoto:
            isShowingPhotoLibrary.wrappedValue.toggle()
        case .takePhoto:
            isShowingCamera.wrappedValue.toggle()
        case .link:
            if selectedTextAttribute.format.hasLink {
                removeLink()
            } else {
                webView.resignFirstResponder()
                alert.state.wrappedValue = .link { url in
                    self.makeLink(url: url)
                }
            }
        case .programMessage:
            // TODO: Handle programmed message
            webView.resignFirstResponder()
            showWorkInProgressSnackBar()
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
            return [.editText, .addFile, .addPhoto, .takePhoto, .link, .programMessage]
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
    case addFile
    case addPhoto
    case takePhoto
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
        case .addFile:
            return MailResourcesAsset.folder.image
        case .addPhoto:
            return MailResourcesAsset.pictureLandscape.image
        case .takePhoto:
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
        case .unorderedList, .editText, .addFile, .addPhoto, .takePhoto, .programMessage:
            return false
        }
    }
}
