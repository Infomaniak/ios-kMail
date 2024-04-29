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

import InfomaniakDI
import MailCore
import MailResources
import RealmSwift
import SwiftUI

struct ComposeMessageSenderMenu: View {
    @EnvironmentObject private var draftContentManager: DraftContentManager
    @EnvironmentObject private var mailboxManager: MailboxManager

    @ObservedResults(Signature.self) private var signatures

    @Binding var currentSignature: Signature?

    let autocompletionType: ComposeViewFieldType?
    let type: ComposeViewFieldType
    let text: String

    private var canSelectSignature: Bool {
        !signatures.isEmpty
    }

    init(
        currentSignature: Binding<Signature?>,
        mailboxManager: MailboxManager,
        autocompletionType: ComposeViewFieldType?,
        type: ComposeViewFieldType,
        text: String
    ) {
        _currentSignature = currentSignature
        _signatures = ObservedResults(Signature.self, configuration: mailboxManager.realmConfiguration)
        self.autocompletionType = autocompletionType
        self.type = type
        self.text = text
    }

    var body: some View {
        if autocompletionType == nil {
            VStack(spacing: 0) {
                HStack {
                    Text(type.title)
                        .textStyle(.bodySecondary)

                    Menu {
                        SenderMenuCell(currentSignature: $currentSignature, signature: nil)
                        ForEach(signatures) { signature in
                            SenderMenuCell(currentSignature: $currentSignature, signature: signature)
                        }
                    } label: {
                        Group {
                            if let currentSignature {
                                Text(currentSignature, format: .signature(style: canSelectSignature ? .long : .short))
                            } else {
                                Text(mailboxManager.mailbox.email)
                            }
                        }
                        .textStyle(.body)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)

                        if canSelectSignature {
                            ChevronIcon(direction: .down)
                        }
                    }
                    .disabled(!canSelectSignature)
                }
                .padding(.vertical, UIPadding.composeViewHeaderCellLargeVertical)
                .padding(.horizontal, UIPadding.composeViewHeaderHorizontal)

                IKDivider()
            }
        }
    }
}

#Preview {
    ComposeMessageSenderMenu(
        currentSignature: .constant(nil),
        mailboxManager: PreviewHelper.sampleMailboxManager,
        autocompletionType: nil,
        type: .from,
        text: "email@email.com"
    )
}
