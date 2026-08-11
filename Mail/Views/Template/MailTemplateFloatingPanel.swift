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
    @Binding var isShowingFloatingPanel: Bool

    @State private var title = "Model"
    @State private var templates: [MailTemplate] = []
    @State private var previewAttributedStrings: [Int: AttributedString] = [:]

    func body(content: Content) -> some View {
        content
            .mailFloatingPanel(isPresented: $isShowingFloatingPanel, title: title) {
                VStack(spacing: IKPadding.mini) {
                    ForEach(templates) { template in
                        Button {
                            print("click on button to open \(template.title)")
                        } label: {
                            HStack(spacing: IKPadding.mini) {
                                VStack(alignment: .leading) {
                                    Text(template.title)
                                        .font(MailTextStyle.header2.font)
                                        .foregroundStyle(MailTextStyle.header2.color)

                                    Text(previewAttributedStrings[template.id] ?? "")
                                        .font(MailTextStyle.bodyMedium.font)
                                        .foregroundStyle(MailTextStyle.bodyMedium.color)
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(IKPadding.mini)

                                MailResourcesAsset.chevronUp.swiftUIImage // TODO: Add left chevron
                                    .iconSize(IKIconSize.medium)
                                    .foregroundStyle(.gray)
                            }
                        }

                        Divider()
                    }
                }
                .padding(IKPadding.medium)
                .task {
                    do {
                        templates = try await MailApiFetcher().mailTemplate()
                        for template in templates {
                            previewAttributedStrings[template.id] = template.body.htmlToAttributedString()
                        }
                    } catch {
                        // handle error
                    }
                }
            }
    }
}

extension String {
    func htmlToAttributedString() -> AttributedString {
        guard let data = data(using: .utf8),
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
