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
import IKSnackbar
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

    @ObservedResults(MailTemplate.self) private var templates

    let mailboxManager: MailboxManager
    let onTemplateSelected: (MailTemplate) async -> Void

    init(mailboxManager: MailboxManager, onTemplateSelected: @escaping (MailTemplate) async -> Void) {
        self.mailboxManager = mailboxManager
        self.onTemplateSelected = onTemplateSelected
        _templates = ObservedResults(MailTemplate.self, configuration: mailboxManager.realmConfiguration)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(templates) { template in
                    NavigationLink(value: template) {
                        VStack(alignment: .leading, spacing: IKPadding.micro) {
                            Text(template.displayName)
                                .font(MailTextStyle.header2.font)
                                .foregroundStyle(MailTextStyle.header2.color)

                            Text(!template.preview.isEmpty ? template.preview : MailResourcesStrings.Localizable.noBodyDescription)
                                .font(MailTextStyle.bodyMediumTertiary.font)
                                .foregroundStyle(MailTextStyle.bodyMediumTertiary.color)
                                .lineLimit(1)
                        }
                        .padding(.vertical, IKPadding.micro)
                    }
                }
            }
            .listStyle(.plain)
            .navigationDestination(for: MailTemplate.self) { template in
                TemplatePreviewView(
                    template: template,
                    onTemplateSelected: onTemplateSelected
                )
            }
            .navigationTitle(MailResourcesStrings.Localizable.modelsTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    ToolbarCloseButton(dismissAction: dismiss)
                }
            }
        }
        .task {
            do {
                try await mailboxManager.refreshTemplates()
            } catch {
                guard !Task.isCancelled else { return }
                
                @LazyInjectService var snackbarPresenter: IKSnackBarPresentable
                snackbarPresenter.show(message: MailResourcesStrings.Localizable.unableLoadTemplate)
            }
        }
    }
}
