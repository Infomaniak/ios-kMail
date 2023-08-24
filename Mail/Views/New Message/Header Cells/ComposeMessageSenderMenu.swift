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

import MailCore
import MailResources
import RealmSwift
import SwiftUI
import InfomaniakDI

struct ComposeMessageSenderMenu: View {
    @EnvironmentObject private var draftContentManager: DraftContentManager

    /// Note:
    /// ObservedResults will invoke a `default.realm` store, and break (no migration block) while a migration is needed in share extension.
    ///
    /// Therefore, I have to pass the correct realm configuration for `Signature.self`, so it can function correctly.
    @ObservedResults(Signature.self, configuration: {
        @InjectService var accountManager: AccountManager
        guard let currentMailboxManager = accountManager.currentMailboxManager else {
            return nil
        }
        return currentMailboxManager.realmConfiguration
    }()) private var signatures

    @Binding var currentSignature: Signature?

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

                    if let currentSignature {
                        Menu {
                            ForEach(signatures) { signature in
                                SenderMenuCell(currentSignature: $currentSignature, signature: signature)
                            }
                        } label: {
                            Text(currentSignature, format: .signature(style: canSelectSignature ? .long : .short))
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
                .padding(.vertical, UIPadding.composeViewHeaderCellLargeVertical)

                IKDivider()
            }
        }
    }
}

struct ComposeMessageStaticText_Previews: PreviewProvider {
    static var previews: some View {
        ComposeMessageSenderMenu(currentSignature: .constant(nil), autocompletionType: nil, type: .from, text: "email@email.com")
    }
}
