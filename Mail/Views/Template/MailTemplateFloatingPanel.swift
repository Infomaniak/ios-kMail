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
import InfomaniakCoreSwiftUI
import MailCore
import MailResources
import SwiftUI

extension View {
    func mailTemplateFloatingPanel(
        isPresented: Binding<Bool>,
        editorBox: EditorBox,
        draft: Draft,
    ) -> some View {
        modifier(
            MailTemplateFloatingPanel(
                isShowingFloatingPanel: isPresented,
                editorBox: editorBox,
                draft: draft
            )
        )
    }
}

struct MailTemplateFloatingPanel: ViewModifier {
    @Binding var isShowingFloatingPanel: Bool
    let editorBox: EditorBox
    let draft: Draft

    @State private var title = "Model"
    @State private var templates: [MailTemplate] = []
    @State private var previewTexts: [Int: String] = [:]

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isShowingFloatingPanel) {
                MailTemplateListView(editorBox: editorBox, draft: draft)
            }
    }
}

struct MailTemplateListView: View {
    @Environment(\.dismiss) private var dismiss

    let editorBox: EditorBox
    let draft: Draft

    @State private var templates: [MailTemplate] = []
    @State private var previewTexts: [Int: String] = [:]

    var body: some View {
        NavigationStack {
            List {
                ForEach(templates) { template in
                    NavigationLink {
                        TemplatePreviewView(template: template, editorBox: editorBox, draft: draft) { dismiss() }
                    } label: {
                        VStack(alignment: .leading) {
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
            .navigationTitle("Models")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if #available(iOS 26.0, *) {
                        Button(role: .close, action: dismiss.callAsFunction)
                    } else {
                        Button(action: dismiss.callAsFunction) {
                            Label("close", systemImage: "xmark")
                        }
                    }
                }
            }
        }
        .task {
            do {
                templates = try await MailApiFetcher().mailTemplate()
                for template in templates {
                    previewTexts[template.id] = (
                        try? await SwiftSoupUtils(fromHTML: template.body).extractText()
                    ) ?? "No body"
                }
            } catch {
                // handle error
            }
        }
    }
}

struct TemplatePreviewView: View {
    let template: MailTemplate
    let editorBox: EditorBox
    let draft: Draft
    let dimissParent: () -> Void

    var body: some View {
        List {
            MessageBodyContentView(
                displayContentBlockedActionView: .constant(false),
                initialContentLoading: .constant(false),
                presentableBody: PresentableBody(
                    body: MailCore.Body(value: ["content": template.body, "type": "html"]),
                    compactBody: template.body,
                    quotes: []
                ),
                blockRemoteContent: false,
                messageUid: "template_\(template.id)",
                messageTheme: .auto,
                mailboxAliases: []
            )
        }
        .listStyle(.plain)
        .listRowSeparator(.hidden)
        .safeAreaInset(edge: .bottom) {
            Button("Inserer") {
                Task {
                    try? await editorBox.editor?.webView
                        .evaluateJavaScript(.insertHTMLAtCaret(template.body))
                }

                if let liveDraft = draft.thaw(), let realm = liveDraft.realm {
                    try? realm.write {
                        if liveDraft.subject.isEmpty {
                            liveDraft.subject = template.displayName
                        }
                    }
                }

                dimissParent()
            }
            .buttonStyle(.ikBorderedProminent)
            .ikButtonFullWidth(true)
            .controlSize(.large)
            .ikButtonTheme(
                IKButtonTheme(
                    primary: DefaultPreferences.accentColor.primary.swiftUIColor,
                    secondary: DefaultPreferences.accentColor.secondary.swiftUIColor,
                    tertiary: Color.gray,
                    disabledPrimary: Color.gray,
                    disabledSecondary: Color.white,
                    error: Color.red,
                    smallFont: .body,
                    mediumFont: .headline
                )
            )
            .padding(.horizontal, IKPadding.large)
            .padding(.bottom, IKPadding.mini)
        }
        .navigationTitle(template.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
