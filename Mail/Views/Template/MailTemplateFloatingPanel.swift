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
import MailCore
import MailResources
import SwiftUI

extension View {
    func mailTemplateFloatingPanel(
        isPresented: Binding<Bool>,
    ) -> some View {
        modifier(
            MailTemplateFloatingPanel(
                isShowingFloatingPanel: isPresented
            )
        )
    }
}

struct MailTemplateFloatingPanel: ViewModifier {
    @Environment(\.dismiss) var dismiss

    @Binding var isShowingFloatingPanel: Bool

    @State private var title = "Model"
    @State private var templates: [MailTemplate] = []
    @State private var previewTexts: [Int: String] = [:]

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isShowingFloatingPanel) {
                NavigationView {
                    VStack(spacing: IKPadding.mini) {
                        ForEach(templates) { template in
                            NavigationLink {
                                TemplatePreviewView(template: template)
                            } label: {
                                HStack(spacing: IKPadding.mini) {
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
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                    MailResourcesAsset.chevronUp.swiftUIImage // TODO: Add left chevron
                                        .iconSize(IKIconSize.medium)
                                        .foregroundStyle(.gray)
                                }
                            }

                            Divider()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.horizontal, IKPadding.medium)
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
}

struct TemplatePreviewView: View {
    let template: MailTemplate

    var body: some View {
        Text(template.body.htmlToAttributedString())
            .font(MailTextStyle.bodyMedium.font)
            .foregroundStyle(MailTextStyle.bodyMedium.color)
            .navigationTitle(template.displayName)
    }
}

extension String {
    func htmlToAttributedString() -> AttributedString {
        let styledHTML = """
        <style>
            body {
                font-family: -apple-system, sans-serif;
                font-size: 15px;
            }
        </style>
        \(self)
        """

        guard let data = styledHTML.data(using: .utf8),
              let nsAttr = try? NSAttributedString(
                  data: data,
                  options: [
                      .documentType: NSAttributedString.DocumentType.html,
                      .characterEncoding: String.Encoding.utf8.rawValue
                  ],
                  documentAttributes: nil
              ) else {
            return AttributedString(self)
        }
        return AttributedString(nsAttr)
    }
}
