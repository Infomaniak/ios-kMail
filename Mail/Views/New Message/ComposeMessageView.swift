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

import InfomaniakCore
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailResources
import Popovers
import RealmSwift
import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect

enum ComposeViewFieldType: Hashable {
    case from, to, cc, bcc, subject, editor, autocomplete
    case chip(Int, Recipient)

    var title: String {
        switch self {
        case .from:
            return MailResourcesStrings.Localizable.fromTitle
        case .to:
            return MailResourcesStrings.Localizable.toTitle
        case .cc:
            return MailResourcesStrings.Localizable.ccTitle
        case .bcc:
            return MailResourcesStrings.Localizable.bccTitle
        case .subject:
            return MailResourcesStrings.Localizable.subjectTitle
        case .editor:
            return "editor"
        case .chip:
            return "Recipient Chip"
        case .autocomplete:
            return "autocomplete"
        }
    }
}

final class NewMessageAlert: SheetState<NewMessageAlert.State> {
    enum State {
        case link(handler: (String) -> Void)
        case emptySubject(handler: () -> Void)
        case externalRecipient(state: DisplayExternalRecipientStatus.State)
    }
}

struct ComposeMessageView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dismissModal) var dismissModal
    @EnvironmentObject private var splitViewManager: SplitViewManager
    @EnvironmentObject private var reviewManager: ReviewManager

    @LazyInjectService private var matomo: MatomoUtils
    @LazyInjectService private var draftManager: DraftManager
    @LazyInjectService private var snackbarPresenter: SnackBarPresentable
    @LazyInjectService private var featureFlagsManager: FeatureFlagsManageable

    @State private var isLoadingContent = true
    @State private var isShowingCancelAttachmentsError = false
    @State private var autocompletionType: ComposeViewFieldType?
    @State private var editorFocus = false
    @State private var currentSignature: Signature?
    @State private var initialAttachments = [Attachable]()
    @State private var isShowingExternalTag = true

    @State private var isShowingAIPopover = false

    @State private var editorModel = RichTextEditorModel()
    @Weak private var scrollView: UIScrollView?

    @StateObject private var attachmentsManager: AttachmentsManager
    @StateObject private var alert = NewMessageAlert()
    @StateObject private var aiModel: AIModel

    @StateRealmObject private var draft: Draft

    @FocusState private var focusedField: ComposeViewFieldType? {
        willSet {
            let editorInFocus = (newValue == .editor)
            editorFocus = editorInFocus
        }
    }

    private let messageReply: MessageReply?
    private let draftContentManager: DraftContentManager
    private let mailboxManager: MailboxManager

    private var isSendButtonDisabled: Bool {
        let disabledState = draft.identityId == nil
            || draft.identityId?.isEmpty == true
            || draft.recipientsAreEmpty
            || !attachmentsManager.allAttachmentsUploaded
        return disabledState
    }

    // MARK: - Init

    init(editedDraft: EditedDraft, mailboxManager: MailboxManager, attachments: [Attachable] = []) {
        messageReply = editedDraft.messageReply

        Self.writeDraftToRealm(mailboxManager.getRealm(), draft: editedDraft.draft)
        _draft = StateRealmObject(wrappedValue: editedDraft.draft)

        draftContentManager = DraftContentManager(
            incompleteDraft: editedDraft.draft,
            messageReply: editedDraft.messageReply,
            mailboxManager: mailboxManager
        )

        self.mailboxManager = mailboxManager
        _attachmentsManager = StateObject(wrappedValue: AttachmentsManager(draft: editedDraft.draft,
                                                                           mailboxManager: mailboxManager))
        _initialAttachments = State(wrappedValue: attachments)

        _aiModel = StateObject(wrappedValue: AIModel(mailboxManager: mailboxManager))
    }

    // MARK: - View

    var body: some View {
        NavigationView {
            composeMessage
        }
        .navigationViewStyle(.stack)
        .task {
            do {
                isLoadingContent = true
                currentSignature = try await draftContentManager.prepareCompleteDraft()
                attachmentsManager.completeUploadedAttachments()
                isLoadingContent = false
            } catch {
                // Unable to get signatures, "An error occurred" and close modal.
                snackbarPresenter.show(message: MailError.unknownError.localizedDescription)
                dismissMessageView()
            }
        }
        .onAppear {
            attachmentsManager.importAttachments(attachments: initialAttachments, draft: draft)
            initialAttachments = []

            if featureFlagsManager.isEnabled(.aiMailComposer) && UserDefaults.shared.shouldPresentAIFeature {
                isShowingAIPopover = true
                return
            }

            switch messageReply?.replyMode {
            case .reply, .replyAll:
                focusedField = .editor
            default:
                focusedField = .to
            }
        }
        .onDisappear {
            draftManager.syncDraft(mailboxManager: mailboxManager)
            if !Bundle.main.isExtension {
                splitViewManager.showReviewAlert = reviewManager.shouldRequestReview()
            }
        }
        .interactiveDismissDisabled()
        .customAlert(isPresented: $alert.isShowing) {
            switch alert.state {
            case .link(let handler):
                AddLinkView(actionHandler: handler)
            case .emptySubject(let handler):
                EmptySubjectView(actionHandler: handler)
            case .externalRecipient(let state):
                ExternalRecipientView(externalTagSate: state, isDraft: true)
            case .none:
                EmptyView()
            }
        }
        .customAlert(isPresented: $isShowingCancelAttachmentsError) {
            AttachmentsUploadInProgressErrorView {
                dismissMessageView()
            }
        }
        .aiDiscoveryPresenter(isPresented: $isShowingAIPopover) {
            DiscoveryView(item: .aiDiscovery, shouldPresentFeature: updateUserDefault) { willShowAIPrompt in
                aiModel.isShowingPrompt = willShowAIPrompt
            }
        }
        .aiPromptPresenter(isPresented: $aiModel.isShowingPrompt) {
            AIPromptView(aiModel: aiModel)
        }
        .sheet(isPresented: $aiModel.isShowingProposition) {
            AIPropositionView(aiModel: aiModel, draft: draft)
        }
        .environmentObject(draftContentManager)
        .matomoView(view: ["ComposeMessage"])
    }

    /// Compose message view
    private var composeMessage: some View {
        ScrollView {
            VStack(spacing: 0) {
                ComposeMessageHeaderView(
                    draft: draft,
                    focusedField: _focusedField,
                    autocompletionType: $autocompletionType,
                    currentSignature: $currentSignature
                )

                if autocompletionType == nil && !isLoadingContent {
                    ComposeMessageBodyView(
                        draft: draft,
                        editorModel: $editorModel,
                        editorFocus: $editorFocus,
                        currentSignature: $currentSignature,
                        isShowingAIPrompt: $aiModel.isShowingPrompt,
                        attachmentsManager: attachmentsManager,
                        alert: alert,
                        messageReply: messageReply
                    )
                }
            }
        }
        .background(MailResourcesAsset.backgroundColor.swiftUIColor)
        .overlay {
            if isLoadingContent {
                progressView
            }
        }
        .introspect(.scrollView, on: .iOS(.v15, .v16, .v17)) { scrollView in
            self.scrollView = scrollView
            scrollView.keyboardDismissMode = .interactive
        }
        .onChange(of: editorModel.height) { _ in
            guard let scrollView else { return }

            let fullSize = scrollView.contentSize.height
            let realPosition = (fullSize - editorModel.height) + editorModel.cursorPosition

            guard realPosition >= 0 else { return }
            let rect = CGRect(x: 0, y: realPosition, width: 1, height: 1)
            scrollView.scrollRectToVisible(rect, animated: true)
        }
        .onChange(of: autocompletionType) { newValue in
            guard newValue != nil else { return }

            let rectTop = CGRect(x: 0, y: 0, width: 1, height: 1)
            scrollView?.scrollRectToVisible(rectTop, animated: true)
        }
        .navigationTitle(MailResourcesStrings.Localizable.buttonNewMessage)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                CloseButton(dismissHandler: didTouchDismiss)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: didTouchSend) {
                    Label(MailResourcesStrings.Localizable.send, image: MailResourcesAsset.send.name)
                }
                .disabled(isSendButtonDisabled)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if isShowingExternalTag {
                let externalTag = draft.displayExternalTag(mailboxManager: mailboxManager)
                switch externalTag {
                case .many, .one:
                    HStack(spacing: UIPadding.medium) {
                        Text(MailResourcesStrings.Localizable.externalDialogTitleRecipient)
                            .foregroundColor(MailResourcesAsset.onTagExternalColor)
                            .textStyle(.bodySmall)

                        Spacer()

                        Button {
                            matomo.track(eventWithCategory: .externals, name: "bannerInfo")
                            alert.state = .externalRecipient(state: externalTag)
                        } label: {
                            MailResourcesAsset.info.swiftUIImage
                                .resizable()
                                .foregroundColor(MailResourcesAsset.onTagExternalColor)
                                .frame(width: 16, height: 16)
                        }

                        Button {
                            matomo.track(eventWithCategory: .externals, name: "bannerManuallyClosed")
                            isShowingExternalTag = false
                        } label: {
                            MailResourcesAsset.close.swiftUIImage
                                .resizable()
                                .foregroundColor(MailResourcesAsset.onTagExternalColor)
                                .frame(width: 16, height: 16)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(value: .regular)
                    .background(MailResourcesAsset.yellowColor.swiftUIColor)
                case .none:
                    EmptyView()
                }
            }
        }
    }

    /// Progress view
    private var progressView: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(MailResourcesAsset.backgroundColor.swiftUIColor)
    }

    // MARK: - Func

    /// Something to dismiss the view regardless of presentation context
    private func dismissMessageView() {
        dismissModal()
        dismiss()
    }

    private func didTouchDismiss() {
        guard attachmentsManager.allAttachmentsUploaded else {
            isShowingCancelAttachmentsError = true
            return
        }
        dismissMessageView()
    }

    private func didTouchSend() {
        guard !draft.subject.isEmpty else {
            matomo.track(eventWithCategory: .newMessage, name: "sendWithoutSubject")
            alert.state = .emptySubject(handler: sendDraft)
            return
        }
        sendDraft()
    }

    private func sendDraft() {
        let sentWithExternals: Bool
        switch draft.displayExternalTag(mailboxManager: mailboxManager) {
        case .one, .many:
            sentWithExternals = true
        case .none:
            sentWithExternals = false
        }

        matomo.trackSendMessage(draft: draft, sentWithExternals: sentWithExternals)
        if let liveDraft = draft.thaw() {
            try? liveDraft.realm?.write {
                liveDraft.action = .send
            }
        }
        dismissMessageView()
    }

    private static func writeDraftToRealm(_ realm: Realm, draft: Draft) {
        try? realm.write {
            draft.action = draft.action == nil && draft.remoteUUID.isEmpty ? .initialSave : .save
            draft.delay = UserDefaults.shared.cancelSendDelay.rawValue

            realm.add(draft, update: .modified)
        }
    }

    private func updateUserDefault(shouldPresentFeature: Bool) {
        UserDefaults.shared.shouldPresentAIFeature = shouldPresentFeature
    }
}

struct ComposeMessageView_Previews: PreviewProvider {
    static var previews: some View {
        ComposeMessageView(
            editedDraft: EditedDraft.new(),
            mailboxManager: PreviewHelper.sampleMailboxManager
        )
    }
}
