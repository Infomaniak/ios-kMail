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
import Foundation
import IKSnackbar
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailResources
import SwiftUI

extension View {
    func mailTemplateFloatingPanel(
        isPresented: Binding<Bool>,
        editorBox: EditorBox,
        draft: Draft,
        templates: [MailTemplate]
    ) -> some View {
        modifier(
            MailTemplateFloatingPanel(
                isShowingFloatingPanel: isPresented,
                editorBox: editorBox,
                draft: draft,
                templates: templates
            )
        )
    }
}

struct MailTemplateFloatingPanel: ViewModifier {
    @Binding var isShowingFloatingPanel: Bool
    let editorBox: EditorBox
    let draft: Draft
    let templates: [MailTemplate]

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isShowingFloatingPanel) {
                MailTemplateListView(editorBox: editorBox, draft: draft, templates: templates)
            }
    }
}

struct MailTemplateListView: View {
    @Environment(\.dismiss) private var dismiss

    let editorBox: EditorBox
    let draft: Draft
    let templates: [MailTemplate]

    @State private var previewTexts: [String: String] = [:]

    var body: some View {
        NavigationStack {
            List {
                ForEach(templates) { template in
                    NavigationLink {
                        TemplatePreviewView(template: template, editorBox: editorBox, draft: draft) { dismiss() }
                    } label: {
                        VStack(alignment: .leading, spacing: IKPadding.micro) {
                            Text(template.displayName)
                                .font(MailTextStyle.header2.font)
                                .foregroundStyle(MailTextStyle.header2.color)

                            if let previewBody = previewTexts[template.id], !previewBody.isEmpty {
                                Text(previewBody)
                                    .font(MailTextStyle.bodyMediumTertiary.font)
                                    .foregroundStyle(MailTextStyle.bodyMediumTertiary.color)
                                    .lineLimit(1)
                            }
                        }
                        .padding(.vertical, IKPadding.micro)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle(MailResourcesStrings.Localizable.modelsTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if #available(iOS 26.0, *) {
                        Button(role: .close, action: dismiss.callAsFunction)
                    } else {
                        Button(action: dismiss.callAsFunction) {
                            Label(MailResourcesStrings.Localizable.buttonClose, systemImage: "xmark")
                        }
                    }
                }
            }
        }
        .task {
            let sources = templates.map { TemplatePreviewSource(id: $0.id, preview: $0.preview, content: $0.content) }
            previewTexts = await Self.previewTexts(for: sources)
        }
    }

    @concurrent
    private static func previewTexts(for sources: [TemplatePreviewSource]) async -> [String: String] {
        var texts = [String: String]()
        for source in sources {
            if !source.preview.isEmpty {
                texts[source.id] = source.preview
            } else {
                let extracted = try? await SwiftSoupUtils(fromHTML: source.content).extractText()
                texts[source.id] = extracted ?? MailResourcesStrings.Localizable.noBodyDescription
            }
        }
        return texts
    }
}

private struct TemplatePreviewSource {
    let id: String
    let preview: String
    let content: String
}

struct TemplatePreviewView: View {
    let template: MailTemplate
    let editorBox: EditorBox
    let draft: Draft
    let dismissParent: () -> Void

    @State private var isInserting = false

    var body: some View {
        List {
            if !template.content.isEmpty {
                MessageBodyContentView(
                    displayContentBlockedActionView: .constant(false),
                    initialContentLoading: .constant(false),
                    presentableBody: {
                        let body = MailCore.Body()
                        body.value = template.content
                        body.type = .textHtml
                        return PresentableBody(body: body, compactBody: template.content, quotes: [])
                    }(),
                    blockRemoteContent: false,
                    messageUid: "template_\(template.id)",
                    messageTheme: .auto,
                    mailboxAliases: []
                )
                .listRowSeparator(.hidden)
                .listRowBackground(MailResourcesAsset.backgroundColor.swiftUIColor)
            }
        }
        .listStyle(.plain)
        .background(MailResourcesAsset.backgroundColor.swiftUIColor)
        .safeAreaInset(edge: .bottom) {
            Button(MailResourcesStrings.Localizable.aiButtonInsert) {
                Task { await insertTemplate() }
            }
            .disabled(isInserting)
            .buttonStyle(.ikBorderedProminent)
            .ikButtonFullWidth(true)
            .controlSize(.large)
            .padding(.horizontal, IKPadding.large)
            .padding(.bottom, IKPadding.mini)
        }
        .navigationTitle(template.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func insertTemplate() async {
        guard !isInserting else { return }
        isInserting = true
        defer { isInserting = false }

        guard let webView = editorBox.editor?.webView else { return }

        do {
            let html = try await Self.cleanedHTML(from: template.content)

            let result = try await webView.evaluateJavaScript(.insertHTMLAtCaret(html))
            guard result as? Bool == true else { return }

            if let liveDraft = draft.thaw(), let realm = liveDraft.realm {
                try? realm.write {
                    if liveDraft.subject.isEmpty {
                        liveDraft.subject = template.title
                    }
                }
            }

            dismissParent()
        } catch {
            @InjectService var snackbarPresenter: IKSnackBarPresentable
            snackbarPresenter.show(message: MailResourcesStrings.Localizable.unableInsertTemplate)
        }
    }

    @concurrent
    private static func cleanedHTML(from html: String) async throws -> String {
        let cleaned = try await SwiftSoupUtils(fromHTML: html).cleanBody()
        return try cleaned.body()?.html() ?? ""
    }
}
