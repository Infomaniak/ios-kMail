/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

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
import SQRichTextEditor
import SwiftUI
import WebKit

struct RichTextEditor: UIViewRepresentable {
    @State private var mustUpdateBody = false

    @Binding var model: RichTextEditorModel
    @Binding var body: String
    @Binding var isShowingCamera: Bool
    @Binding var isShowingFileSelection: Bool
    @Binding var isShowingPhotoLibrary: Bool
    @Binding var becomeFirstResponder: Bool
    @Binding var isShowingAIPrompt: Bool
    @Binding var isShowingAlert: NewMessageAlert?

    let blockRemoteContent: Bool

    init(model: Binding<RichTextEditorModel>,
         body: Binding<String>,
         isShowingCamera: Binding<Bool>,
         isShowingFileSelection: Binding<Bool>,
         isShowingPhotoLibrary: Binding<Bool>,
         becomeFirstResponder: Binding<Bool>,
         isShowingAIPrompt: Binding<Bool>,
         isShowingAlert: Binding<NewMessageAlert?>,
         blockRemoteContent: Bool) {
        _model = model
        _body = body
        _isShowingCamera = isShowingCamera
        _isShowingFileSelection = isShowingFileSelection
        _isShowingPhotoLibrary = isShowingPhotoLibrary
        _becomeFirstResponder = becomeFirstResponder
        _isShowingAIPrompt = isShowingAIPrompt
        _isShowingAlert = isShowingAlert
        self.blockRemoteContent = blockRemoteContent
    }

    class Coordinator: SQTextEditorDelegate {
        var parent: RichTextEditor

        init(_ parent: RichTextEditor) {
            self.parent = parent
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(requireBodyUpdate),
                name: Notification.Name.updateComposeMessageBody,
                object: nil
            )
        }

        @MainActor
        func insertBody(editor: SQTextEditorView) async throws {
            guard let editor = (editor as? MailEditorView) else { throw MailError.unknownError }
            try await insertBody(editor: editor)
        }

        @MainActor
        func insertBody(editor: MailEditorView) async throws {
            try await editor.contentBlocker.setRemoteContentBlocked(parent.blockRemoteContent)
            editor.clear()
            try await editor.insertRawHTML(parent.body)
            editor.moveCursorToStart()
            editor.webView.scrollView.isScrollEnabled = false
            parent.model.height = CGFloat(editor.contentHeight)
        }

        func editorDidLoad(_ editor: SQTextEditorView) {
            Task {
                do {
                    try await insertBody(editor: editor)
                } catch {
                    print("Failed to load editor: \(error)")
                }
            }
        }

        func editor(_ editor: SQTextEditorView, contentHeightDidChange height: Int) {
            parent.model.height = CGFloat(height)
        }

        func editor(_ editor: SQTextEditorView, cursorPositionDidChange position: SQEditorCursorPosition) {
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
            if parentBody != content {
                parent.body = content
            }
        }

        @objc func requireBodyUpdate() {
            parent.mustUpdateBody = true
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    func makeUIView(context: Context) -> MailEditorView {
        let richTextEditor = MailEditorView(
            isShowingCamera: $isShowingCamera,
            isShowingFileSelection: $isShowingFileSelection,
            isShowingPhotoLibrary: $isShowingPhotoLibrary,
            isShowingAIPrompt: $isShowingAIPrompt,
            isShowingAlert: $isShowingAlert
        )
        richTextEditor.delegate = context.coordinator
        return richTextEditor
    }

    func updateUIView(_ uiView: MailEditorView, context: Context) {
        if becomeFirstResponder {
            DispatchQueue.main.async {
                uiView.setBecomeFirstResponder()
                becomeFirstResponder = false
            }
        }
        if mustUpdateBody {
            Task {
                mustUpdateBody = false
                try await context.coordinator.insertBody(editor: uiView)
            }
        }
    }

    static func dismantleUIView(_ uiView: MailEditorView, coordinator: Coordinator) {
        uiView.webView.configuration.userContentController.removeAllScriptMessageHandlers()
    }
}

struct RichTextEditorModel {
    var cursorPosition: CGFloat = 0
    var height: CGFloat = 0
}

final class MailEditorView: SQTextEditorView {
    @LazyInjectService var matomo: MatomoUtils

    lazy var toolbar = getToolbar()
    var isShowingCamera: Binding<Bool>
    var isShowingFileSelection: Binding<Bool>
    var isShowingPhotoLibrary: Binding<Bool>
    var isShowingAIPrompt: Binding<Bool>
    var isShowingAlert: Binding<NewMessageAlert?>

    var toolbarStyle = ToolbarStyle.main

    init(isShowingCamera: Binding<Bool>, isShowingFileSelection: Binding<Bool>, isShowingPhotoLibrary: Binding<Bool>,
         isShowingAIPrompt: Binding<Bool>, isShowingAlert: Binding<NewMessageAlert?>) {
        self.isShowingCamera = isShowingCamera
        self.isShowingFileSelection = isShowingFileSelection
        self.isShowingPhotoLibrary = isShowingPhotoLibrary
        self.isShowingAIPrompt = isShowingAIPrompt
        self.isShowingAlert = isShowingAlert
        super.init()
    }

    public func setBecomeFirstResponder() {
        webView.becomeFirstResponder()
    }

    lazy var contentBlocker = ContentBlocker(webView: editorWebView)

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

        let css = customCss ?? MessageWebViewUtils.generateCSS(for: .editor)
        let cssStyle = "(() => { document.head.innerHTML += `\(css)`; })()"
        let cssScript = WKUserScript(source: cssStyle, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        config.userContentController.addUserScript(cssScript)

        let _webView = WKWebView(frame: .zero, configuration: config)
        _webView.translatesAutoresizingMaskIntoConstraints = false
        _webView.navigationDelegate = self
        _webView.allowsLinkPreview = false
        _webView.addInputAccessoryView(toolbar: self.toolbar)
        _webView.isOpaque = false
        _webView.backgroundColor = .clear
        self.updateToolbarItems(style: .main)
        _webView.scrollView.keyboardDismissMode = .interactive

        #if DEBUG && !TEST
        if #available(iOS 17.0, *) {
            _webView.isInspectable = true
        }
        #endif

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

    // MARK: - Custom function

    func insertRawHTML(_ html: String) async throws {
        let cleanedHTML = try await SwiftSoupUtils(fromHTMLFragment: html).cleanBody()
        try await webView.evaluateJavaScript("document.getElementById('editor').innerHTML = `\(cleanedHTML)`")
    }

    // MARK: - Editor methods

    /// Removes any current selection and moves the cursor to the very beginning of the document.
    func moveCursorToStart(completion: ((_ error: Error?) -> Void)? = nil) {
        callEditorMethod(name: "moveCursorToStart", completion: completion)
    }

    func makeUnorderedList(completion: ((_ error: Error?) -> Void)? = nil) {
        callEditorMethod(name: "makeUnorderedList", completion: completion)
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

    public func getToolbar() -> UIToolbar {
        let newToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 48))
        UIConstants.applyComposeViewStyle(to: newToolbar)
        return newToolbar
    }

    @objc func onToolbarClick(sender: UIBarButtonItem) {
        guard let toolbarAction = ToolbarAction(rawValue: sender.tag) else { return }

        if let matomoName = toolbarAction.matomoName {
            matomo.track(eventWithCategory: .editorActions, name: matomoName)
        }

        switch toolbarAction {
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
        case .ai:
            webView.resignFirstResponder()
            isShowingAIPrompt.wrappedValue = true
        case .addFile:
            isShowingFileSelection.wrappedValue = true
        case .addPhoto:
            isShowingPhotoLibrary.wrappedValue = true
        case .takePhoto:
            isShowingCamera.wrappedValue = true
        case .link:
            if selectedTextAttribute.format.hasLink {
                removeLink()
            } else {
                webView.resignFirstResponder()
                isShowingAlert.wrappedValue = NewMessageAlert(type: .link(handler: { url in
                    self.makeLink(url: url)
                }))
            }
        case .programMessage:
            // TODO: Handle programmed message
            showWorkInProgressSnackBar()
        }
    }
}

enum ToolbarStyle {
    case main
    case textEdition

    var actions: [ToolbarAction] {
        switch self {
        case .main:
            @InjectService var featureFlagsManageable: FeatureFlagsManageable
            var mainActions: [ToolbarAction] = [.editText, .addFile, .addPhoto, .takePhoto, .link]
            featureFlagsManageable.feature(.aiMailComposer, on: {
                mainActions.insert(.ai, at: 1)
            }, off: nil)
            return mainActions
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
    case ai
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
        case .ai:
            return MailResourcesAsset.aiWriter.image
        case .addFile:
            return MailResourcesAsset.folder.image
        case .addPhoto:
            return MailResourcesAsset.pictureLandscape.image
        case .takePhoto:
            return MailResourcesAsset.photo.image
        case .link:
            return MailResourcesAsset.hyperlink.image
        case .programMessage:
            return MailResourcesAsset.waitingMessage.image
        }
    }

    var tint: UIColor {
        if self == .ai {
            return MailResourcesAsset.aiColor.color
        } else {
            return MailResourcesAsset.textSecondaryColor.color
        }
    }

    var matomoName: String? {
        switch self {
        case .bold:
            return "bold"
        case .italic:
            return "italic"
        case .underline:
            return "underline"
        case .strikeThrough:
            return "strikeThrough"
        case .unorderedList:
            return "unorderedList"
        case .ai:
            return "aiWriter"
        case .addFile:
            return "importFile"
        case .addPhoto:
            return "importImage"
        case .takePhoto:
            return "importFromCamera"
        case .link:
            return "addLink"
        case .programMessage:
            return "postpone"
        default:
            return nil
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
        case .unorderedList, .editText, .ai, .addFile, .addPhoto, .takePhoto, .programMessage:
            return false
        }
    }
}
