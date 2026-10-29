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
import MailCoreUI
import MailResources
import RealmSwift
import SwiftUI

extension View {
    func mailTemplateFloatingPanel(
        isPresented: Binding<Bool>,
        mailboxManager: MailboxManager,
        onTemplateSelected: @escaping (MailTemplate) async -> Void
    ) -> some View {
        modifier(
            MailTemplateFloatingPanelModifier(
                isShowingFloatingPanel: isPresented,
                mailboxManager: mailboxManager,
                onTemplateSelected: onTemplateSelected
            )
        )
    }
}

struct MailTemplateFloatingPanelModifier: ViewModifier {
    @Binding var isShowingFloatingPanel: Bool
    let mailboxManager: MailboxManager
    let onTemplateSelected: (MailTemplate) async -> Void

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isShowingFloatingPanel) {
                MailTemplateListView(
                    mailboxManager: mailboxManager,
                    onTemplateSelected: onTemplateSelected
                )
            }
    }
}

struct MailTemplateListView: View {
    @Environment(\.dismiss) private var dismiss
    @LazyInjectService private var snackbarPresenter: IKSnackBarPresentable

    @ObservedResults(MailTemplate.self) private var templates

    let mailboxManager: MailboxManager
    let onTemplateSelected: (MailTemplate) async -> Void

    @State private var previewTexts: [String: String] = [:]

    init(mailboxManager: MailboxManager, onTemplateSelected: @escaping (MailTemplate) async -> Void) {
        self.mailboxManager = mailboxManager
        self.onTemplateSelected = onTemplateSelected
        _templates = ObservedResults(MailTemplate.self, configuration: mailboxManager.realmConfiguration)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(templates) { template in
                    NavigationLink {
                        TemplatePreviewView(template: template, onTemplateSelected: onTemplateSelected)
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
                ToolbarItem(placement: .topBarLeading) {
                    ToolbarCloseButton(dismissAction: dismiss)
                }
            }
        }
        .task(id: templates.count) {
            previewTexts = await Self.previewTexts(for: Array(templates.map { $0.freeze() }))
        }
        .task {
            do {
                try await mailboxManager.refreshTemplates()
            } catch {
                guard !Task.isCancelled else { return }
                snackbarPresenter.show(message: MailResourcesStrings.Localizable.unableLoadTemplate)
            }
        }
    }

    @concurrent
    private static func previewTexts(for sources: [MailTemplate]) async -> [String: String] {
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

struct TemplatePreviewView: View {
    let template: MailTemplate
    let onTemplateSelected: (MailTemplate) async -> Void

    @State private var isSelectingTemplate = false

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
                selectTemplate()
            }
            .disabled(isSelectingTemplate)
            .buttonStyle(.ikBorderedProminent)
            .ikButtonFullWidth(true)
            .controlSize(.large)
            .padding(.horizontal, IKPadding.large)
            .padding(.bottom, IKPadding.mini)
        }
        .navigationTitle(template.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func selectTemplate() {
        guard !isSelectingTemplate else { return }
        isSelectingTemplate = true
        Task {
            await onTemplateSelected(template)
            isSelectingTemplate = false
        }
    }
}
