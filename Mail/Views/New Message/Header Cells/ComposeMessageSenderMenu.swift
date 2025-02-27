/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailCoreUI
import RealmSwift
import SwiftUI

struct ComposeMessageSenderMenu: View {
    @EnvironmentObject private var mailboxManager: MailboxManager

    @ObservedResults(Signature.self) private var signatures

    @Binding var currentSignature: Signature?

    let autocompletionType: ComposeViewFieldType?
    let type: ComposeViewFieldType
    let incompleteDraft: Draft

    private var canSelectSignature: Bool {
        !signatures.isEmpty
    }

    private var signatureLabel: String {
        currentSignature?.formatted(style: canSelectSignature ? .long : .short) ?? mailboxManager.mailbox.emailIdn
    }

    init(
        currentSignature: Binding<Signature?>,
        mailboxManager: MailboxManager,
        autocompletionType: ComposeViewFieldType?,
        type: ComposeViewFieldType,
        incompleteDraft: Draft
    ) {
        _currentSignature = currentSignature
        _signatures = ObservedResults(Signature.self, configuration: mailboxManager.realmConfiguration)
        self.autocompletionType = autocompletionType
        self.type = type
        self.incompleteDraft = incompleteDraft
    }

    var body: some View {
        if autocompletionType == nil {
            VStack(spacing: 0) {
                HStack {
                    Text(type.title)
                        .textStyle(.bodySecondary)

                    Menu {
                        SenderMenuCell(currentSignature: $currentSignature, signature: nil, incompleteDraft: incompleteDraft)
                        ForEach(signatures) { signature in
                            SenderMenuCell(
                                currentSignature: $currentSignature,
                                signature: signature,
                                incompleteDraft: incompleteDraft
                            )
                        }
                    } label: {
                        Text(signatureLabel)
                            .textStyle(.body)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if canSelectSignature {
                            ChevronIcon(direction: .down)
                        }
                    }
                    .disabled(!canSelectSignature)
                }
                .padding(.vertical, IKPadding.composeViewHeaderCellLargeVertical)
                .padding(.horizontal, IKPadding.composeViewHeaderHorizontal)

                IKDivider()
            }
        }
    }
}

#Preview {
    let draft = Draft()
    ComposeMessageSenderMenu(
        currentSignature: .constant(nil),
        mailboxManager: PreviewHelper.sampleMailboxManager,
        autocompletionType: nil,
        type: .from,
        incompleteDraft: draft
    )
}
