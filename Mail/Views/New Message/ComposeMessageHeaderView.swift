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

import MailCore
import MailCoreUI
import MailResources
import RealmSwift
import SwiftUI

struct ComposeMessageHeaderView: View {
    @EnvironmentObject private var mailboxManager: MailboxManager

    @State private var showRecipientsFields = false
    @State private var scheduledAbsenceSummary: ScheduledAbsenceSummary?

    @ObservedRealmObject var draft: Draft

    @FocusState var focusedField: ComposeViewFieldType?

    @Binding var autocompletionType: ComposeViewFieldType?
    @Binding var currentSignature: Signature?

    private var totalRecipients: Int {
        return draft.to.count + draft.cc.count + draft.bcc.count
    }

    private var isRecipientLimitExceeded: Bool {
        return totalRecipients > 99
    }

    private var scheduledAbsenceRecipients: [ScheduledAbsenceRecipient] {
        return ScheduledAbsenceLookup.recipients(
            draft.allRecipients
                .filter { !$0.isMe(currentMailboxEmail: mailboxManager.mailbox.email) }
                .map { ScheduledAbsenceRecipient(email: $0.email, name: $0.name) }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            ComposeMessageSenderMenu(
                currentSignature: $currentSignature,
                mailboxManager: mailboxManager,
                autocompletionType: autocompletionType,
                type: .from,
                draft: draft
            )

            ComposeMessageCellRecipients(
                recipients: $draft.to,
                showRecipientsFields: $showRecipientsFields,
                autocompletionType: $autocompletionType,
                focusedField: _focusedField,
                type: .to,
                areCCAndBCCEmpty: draft.cc.isEmpty && draft.bcc.isEmpty,
                isRecipientLimitExceeded: isRecipientLimitExceeded
            ) { recipients in
                try append(recipients, to: \.to, in: draft)
            }
            .accessibilityElement(children: .contain)

            if showRecipientsFields {
                ComposeMessageCellRecipients(
                    recipients: $draft.cc,
                    showRecipientsFields: $showRecipientsFields,
                    autocompletionType: $autocompletionType,
                    focusedField: _focusedField,
                    type: .cc,
                    isRecipientLimitExceeded: isRecipientLimitExceeded
                ) { recipients in
                    try append(recipients, to: \.cc, in: draft)
                }
                .accessibilityLabel(MailResourcesStrings.Localizable.ccTitle)

                ComposeMessageCellRecipients(
                    recipients: $draft.bcc,
                    showRecipientsFields: $showRecipientsFields,
                    autocompletionType: $autocompletionType,
                    focusedField: _focusedField,
                    type: .bcc,
                    isRecipientLimitExceeded: isRecipientLimitExceeded
                ) { recipients in
                    try append(recipients, to: \.bcc, in: draft)
                }
                .accessibilityLabel(MailResourcesStrings.Localizable.bccTitle)
            }

            ComposeMessageCellTextField(
                text: $draft.subject,
                focusedField: _focusedField,
                autocompletionType: autocompletionType,
                type: .subject
            )
            .accessibilityLabel(MailResourcesStrings.Localizable.subjectTitle)

            if autocompletionType == nil, let scheduledAbsenceSummary {
                ScheduledAbsenceHeaderView(
                    summary: scheduledAbsenceSummary,
                    showTopSeparator: false,
                    showBottomSeparator: true
                )
            }
        }
        .environment(\.scheduledAbsenceDescriptions, scheduledAbsenceSummary?.descriptionsByEmail ?? [:])
        .task(id: "\(scheduledAbsenceRecipients.map(\.email))-\(String(describing: draft.scheduleDate))") {
            await fetchScheduledAbsences()
        }
        .onAppear {
            showRecipientsFields = !draft.bcc.isEmpty || !draft.cc.isEmpty
        }
    }

    private func fetchScheduledAbsences() async {
        guard mailboxManager.featureFlagsManager.isEnabled(.scheduledAbsence) else { return }

        let recipients = scheduledAbsenceRecipients
        let emails = recipients.map(\.email)
        let now = draft.scheduleDate ?? Date()
        guard !emails.isEmpty else {
            scheduledAbsenceSummary = nil
            return
        }

        guard await (try? Task.sleep(for: .milliseconds(300))) != nil else { return }

        let absences = try? await mailboxManager.apiFetcher.activeScheduledAbsences(emails: emails, startingAt: now)
        guard !Task.isCancelled else { return }

        scheduledAbsenceSummary = absences.map {
            ScheduledAbsenceSummary(absencesByEmail: $0, orderedRecipients: recipients, now: now)
        }
    }

    private func append(
        _ recipients: [Recipient],
        to keyPath: ReferenceWritableKeyPath<Draft, RealmSwift.List<Recipient>>,
        in draft: Draft
    ) throws {
        guard !draft.isInvalidated,
              draft.isManagedByRealm,
              let liveDraft = draft.thaw(),
              let realm = liveDraft.realm else {
            throw MailError.draftNotFound
        }

        try realm.safeWrite {
            liveDraft[keyPath: keyPath].append(objectsIn: recipients)
        }
    }
}

#Preview {
    ComposeMessageHeaderView(draft: Draft(), autocompletionType: .constant(nil), currentSignature: .constant(nil))
        .environmentObject(PreviewHelper.sampleMailboxManager)
}
