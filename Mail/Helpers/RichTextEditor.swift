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
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
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
    private lazy var editorWebView: WKWebView = {
        let config = WKWebViewConfiguration()
        config.preferences = WKPreferences()
        config.preferences.minimumFontSize = 10
        config.preferences.javaScriptEnabled = true
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
}
