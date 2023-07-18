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

import RealmSwift
import MailCore
import MailResources
import SwiftUI

struct ComposeMessageSenderMenu: View {
    @EnvironmentObject private var draftContentManager: DraftContentManager

    @State private var selectedSignature: Signature?

    @ObservedResults(Signature.self) private var signatures

    let autocompletionType: ComposeViewFieldType?
    let type: ComposeViewFieldType
    let text: String

    private var canSelectSignature: Bool {
        signatures.count > 1
    }

    var body: some View {
        if autocompletionType == nil {
            VStack(spacing: 0) {
                HStack {
                    Text(type.title)
                        .textStyle(.bodySecondary)

                    if let selectedSignature {
                        Menu {
                            ForEach(signatures) { signature in
                                Button {
                                    withAnimation {
                                        self.selectedSignature = signature
                                    }
                                    draftContentManager.updateSignature(with: signature)
                                    NotificationCenter.default.post(name: Notification.Name.signatureDidChanged, object: nil)
                                } label: {
                                    Label {
                                        Text("\(signature.fullName) (\(signature.name))")
                                    } icon: {
                                        if signature == selectedSignature {
                                            MailResourcesAsset.check.swiftUIImage
                                        }
                                    }

                                    Text(signature.senderIdn)
                                }

                            }
                        } label: {
                            Text("\(selectedSignature.fullName) <\(selectedSignature.senderIdn)> (\(selectedSignature.name))")
                                .textStyle(.body)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            if canSelectSignature {
                                ChevronIcon(style: .down)
                            }
                        }
                        .disabled(!canSelectSignature)
                    }
                }
                .padding(.vertical, UIConstants.composeViewHeaderCellLargeVerticalSpacing)

                IKDivider()
            }
            .onAppear {
                selectedSignature = Array(signatures).defaultSignature
            }
        }
    }
}

struct ComposeMessageStaticText_Previews: PreviewProvider {
    static var previews: some View {
        ComposeMessageSenderMenu(autocompletionType: nil, type: .from, text: "myaddress@email.com")
    }
}
