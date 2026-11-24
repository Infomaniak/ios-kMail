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
import InfomaniakCoreCommonUI
import InfomaniakDI
import MailCore
import MailResources
import SwiftUI

struct TemplatePreviewView: View {
    let template: MailTemplate
    let onTemplateSelected: (MailTemplate) async -> Void

    @State private var isSelectingTemplate = false

    private let presentableBody: PresentableBody

    init(template: MailTemplate, onTemplateSelected: @escaping (MailTemplate) async -> Void) {
        self.template = template
        self.onTemplateSelected = onTemplateSelected

        let body = MailCore.Body()
        body.value = template.content
        body.type = .textHtml
        presentableBody = PresentableBody(body: body, compactBody: template.content, quotes: [])
    }

    var body: some View {
        ScrollView {
            if !template.content.isEmpty {
                MessageBodyContentView(
                    displayContentBlockedActionView: .constant(false),
                    initialContentLoading: .constant(false),
                    presentableBody: presentableBody,
                    blockRemoteContent: false,
                    messageUid: "template_\(template.id)",
                    messageTheme: .auto,
                    mailboxAliases: []
                )
            }
        }
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
    }

    private func selectTemplate() {
        guard !isSelectingTemplate else { return }
        isSelectingTemplate = true

        @InjectService var matomo: MatomoUtils
        matomo.track(eventWithCategory: .mailTemplateSheet, name: "insert")

        Task {
            await onTemplateSelected(template)
            isSelectingTemplate = false
        }
    }
}
