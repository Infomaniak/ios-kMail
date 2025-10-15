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
import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import InfomaniakRichHTMLEditor
import KSuite
import MailCore
import MailCoreUI
import MailResources
import Popovers
import RealmSwift
import SwiftModalPresentation
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

struct NewMessageAlert: Identifiable {
    let id = UUID()
    let type: NewMessageAlertType
}

enum NewMessageAlertType {
    case emptySubject(handler: () -> Void)
}

struct ComposeMessageView: View {
    @InjectService private var platformDetector: PlatformDetectable
    @InjectService private var featureFlagsManager: FeatureFlagsManageable
    @LazyInjectService private var matomo: MatomoUtils
    @LazyInjectService private var draftManager: DraftManager
    @LazyInjectService private var snackbarPresenter: SnackBarPresentable
    @LazyInjectService private var reviewManager: ReviewManageable

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dismissModal) private var dismissModal
    @EnvironmentObject private var mainViewState: MainViewState

    @State private var isLoadingContent = true
    @ModalState(context: ContextKeys.compose) private var isShowingCancelAttachmentsError = false
    @ModalState(wrappedValue: nil, context: ContextKeys.compose) private var isShowingAlert: NewMessageAlert?
    @State private var autocompletionType: ComposeViewFieldType?
    @State private var currentSignature: Signature?
    @State private var initialAttachments = [Attachable]()
    @State private var isShowingSchedulePanel = false
    @State private var isShowingMyKSuitePanel = false
    @State private var isShowingKSuiteProPanel = false

    @State private var isShowingEncryptStatePanel = false

    @Weak private var scrollView: UIScrollView?

    @StateObject private var draftContentManager: DraftContentManager
    @StateObject private var attachmentsManager: AttachmentsManager
    @StateObject private var aiModel: AIModel
    @StateObject private var textAttributes = TextAttributes()

    @FocusState private var focusedField: ComposeViewFieldType?

    @ObservedRealmObject private var draft: Draft

    private let messageReply: MessageReply?
    private let mailboxManager: MailboxManager
    private let htmlAttachments: [HTMLAttachable]

    private var isSendButtonDisabled: Bool {
        let encryptionReady = (draft.encrypted && draft.encryptionPassword.isEmpty) ? draft.allRecipients
            .allSatisfy { $0.canAutoEncrypt } : true
        return draft.recipientsAreEmpty || !attachmentsManager.allAttachmentsUploaded || !encryptionReady
    }

    private var isScheduleSendButtonDisabled: Bool {
        return draft.recipientsAreEmpty || !attachmentsManager.allAttachmentsUploaded
    }

    // MARK: - Init

    init(
        draft: Draft,
        mailboxManager: MailboxManager,
        messageReply: MessageReply? = nil,
        attachments: [Attachable] = [],
        htmlAttachments: [HTMLAttachable] = []
    ) {
        self.messageReply = messageReply
        self.htmlAttachments = htmlAttachments

        _draft = ObservedRealmObject(wrappedValue: draft)

        _draftContentManager = StateObject(wrappedValue: DraftContentManager(
            draftLocalUUID: draft.localUUID,
            messageReply: messageReply,
            mailboxManager: mailboxManager
        ))

        self.mailboxManager = mailboxManager
        _attachmentsManager = StateObject(wrappedValue: AttachmentsManager(draftLocalUUID: draft.localUUID,
                                                                           mailboxManager: mailboxManager))
        _initialAttachments = State(wrappedValue: attachments)

        _aiModel = StateObject(wrappedValue: AIModel(
            mailboxManager: mailboxManager,
            draft: draft,
            isReplying: messageReply?.isReplying == true
        ))
    }

    // MARK: - View

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ComposeMessageHeaderView(
                    draft: draft,
                    focusedField: _focusedField,
                    autocompletionType: $autocompletionType,
                    currentSignature: $currentSignature
                )
                .environment(\.draftEncryption, draft.encrypted ?
                    .encrypted(passwordSecured: !draft.encryptionPassword.isEmpty) :
                    .none)

                if autocompletionType == nil && !isLoadingContent {
                    ComposeMessageBodyView(
                        textAttributes: textAttributes,
                        focusedField: _focusedField,
                        draftBody: $draftContentManager.draftContent,
                        draft: draft,
                        isShowingAI: $aiModel.isShowingPrompt,
                        messageReply: messageReply
                    )
                    .environmentObject(attachmentsManager)
                }
            }
        }
        .availableSpatialTapGesture { location in
            // If the user directly tap on the UIScrollView, and not a
            // subview like a TextField, we should target the editor
            let targetView = scrollView?.hitTest(location, with: nil)
            if targetView is UIScrollView {
                focusedField = .editor
            }
        }
        .baseComposeMessageToolbar(dismissHandler: didTouchDismiss)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if platformDetector.isMac && featureFlagsManager.isEnabled(.mailComposeEncrypted) {
                    EncryptionButton(isShowingEncryptStatePanel: $isShowingEncryptStatePanel, draft: draft)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                if featureFlagsManager.isEnabled(.scheduleSendDraft) {
                    Button {
                        if draft.encrypted {
                            snackbarPresenter
                                .show(message: MailResourcesStrings.Localizable.encryptedMessageSnackbarScheduledUnavailable)
                        } else {
                            isShowingSchedulePanel = true
                        }
                    } label: {
                        Label(
                            MailResourcesStrings.Localizable.scheduleSendingTitle,
                            asset: MailResourcesAsset.clockPaperplane.swiftUIImage
                        )
                    }
                    .disabled(isScheduleSendButtonDisabled)
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button(action: didTouchSend) {
                    Label(MailResourcesStrings.Localizable.send, asset: MailResourcesAsset.send.swiftUIImage)
                }
                .disabled(isSendButtonDisabled)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !platformDetector.isMac {
                EditorMobileToolbarView(
                    textAttributes: textAttributes,
                    isShowingAI: $aiModel.isShowingPrompt,
                    isShowingKSuiteProPanel: $isShowingKSuiteProPanel,
                    isShowingMyKSuitePanel: $isShowingMyKSuitePanel,
                    isShowingEncryptStatePanel: $isShowingEncryptStatePanel,
                    draft: draft,
                    isEditorFocused: focusedField == .editor
                )
                .environmentObject(attachmentsManager)
            }
        }
        .background(MailResourcesAsset.backgroundColor.swiftUIColor)
        .overlay {
            if isLoadingContent {
                progressView
            }
        }
        .introspect(.scrollView, on: .iOS(.v15, .v16, .v17, .v18, .v26)) { scrollView in
            guard self.scrollView != scrollView else { return }
            self.scrollView = scrollView
            scrollView.keyboardDismissMode = .interactive
        }
        .onChange(of: autocompletionType) { newValue in
            guard newValue != nil else { return }

            let rectTop = CGRect(x: 0, y: 0, width: 1, height: 1)
            scrollView?.scrollRectToVisible(rectTop, animated: true)
        }
        .safeAreaInset(edge: .bottom) {
            ExternalTagBottomView(externalTag: draft.displayExternalTag(mailboxManager: mailboxManager))
        }
        .task {
            do {
                isLoadingContent = true
                currentSignature = try await draftContentManager.prepareCompleteDraft(incompleteDraft: draft)

                await withTaskGroup(of: Void.self) { group in
                    group.addTask {
                        await attachmentsManager.completeUploadedAttachments()
                    }
                    group.addTask {
                        await attachmentsManager.processHTMLAttachments(htmlAttachments, draftContentManager: draftContentManager)
                    }
                }

                aiModel.draftContentManager = draftContentManager
                draftContentManager.startObservingDraft()

                isLoadingContent = false
            } catch {
                snackbarPresenter.show(message: MailError.unknownError.errorDescription ?? "")
                dismissMessageView()
            }
        }
        .onAppear {
            attachmentsManager.importAttachments(
                attachments: initialAttachments,
                draft: draft,
                disposition: AttachmentDisposition.defaultDisposition
            )
            initialAttachments = []

            if featureFlagsManager.isEnabled(.aiMailComposer)
                && UserDefaults.shared.shouldPresentAIFeature
                && !platformDetector.isRunningUITests {
                aiModel.isShowingDiscovery = true
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
            guard !platformDetector.isMac else {
                return
            }

            let shouldShowSnackbar = !Bundle.main.isExtension

            let canShowReview = !Bundle.main.isExtension &&
                !Bundle.main.isRunningInTestFlight &&
                !mainViewState.isShowingSetAppAsDefaultDiscovery &&
                !platformDetector.isRunningUITests
            if canShowReview {
                mainViewState.isShowingReviewAlert = reviewManager.shouldRequestReview()
            }

            draftManager.startSyncDraft(
                mailboxManager: mailboxManager,
                showSnackbar: shouldShowSnackbar,
                changeFolderAction: changeSelectedFolder
            ) { currentPack in
                if currentPack == .kSuiteFree {
                    mainViewState.isShowingKSuiteProUpgrade = true
                    matomo.track(eventWithCategory: .kSuiteProUpgradeBottomSheet, name: "dailyLimitReachedUpgrade")
                } else if currentPack == .myKSuiteFree {
                    mainViewState.isShowingMyKSuiteUpgrade = true
                    matomo.track(eventWithCategory: .myKSuiteUpgradeBottomSheet, name: "dailyLimitReachedUpgrade")
                }
            }
        }
        .mailCustomAlert(item: $isShowingAlert) { alert in
            switch alert.type {
            case .emptySubject(let handler):
                EmptySubjectView(actionHandler: handler)
            }
        }
        .mailCustomAlert(isPresented: $isShowingCancelAttachmentsError) {
            AttachmentsUploadInProgressErrorView {
                dismissMessageView()
            }
        }
        .mailDiscoveryPresenter(isPresented: $aiModel.isShowingDiscovery) {
            DiscoveryView(item: .aiDiscovery) {
                UserDefaults.shared.shouldPresentAIFeature = false
            } completionHandler: { willShowAIPrompt in
                aiModel.isShowingPrompt = willShowAIPrompt

                if willShowAIPrompt {
                    matomo.track(eventWithCategory: .aiWriter, name: "discoverNow")
                } else {
                    matomo.track(eventWithCategory: .aiWriter, name: "discoverLater")
                }
            }
        }
        .aiPromptPresenter(isPresented: $aiModel.isShowingPrompt) {
            AIPromptView(aiModel: aiModel)
        }
        .mailMyKSuiteFloatingPanel(isPresented: $isShowingMyKSuitePanel, configuration: .mail)
        .kSuitePanel(
            isPresented: $isShowingKSuiteProPanel,
            backgroundColor: MailResourcesAsset.backgroundSecondaryColor.swiftUIColor,
            configuration: .standard,
            isAdmin: mailboxManager.mailbox.ownerOrAdmin
        )
        .sheet(isPresented: $aiModel.isShowingProposition) {
            AIPropositionView(aiModel: aiModel)
        }
        .environmentObject(draftContentManager)
        .matomoView(view: ["ComposeMessage"])
        .scheduleFloatingPanel(
            isPresented: $isShowingSchedulePanel,
            type: .scheduledDraft,
            isUpdating: false,
            initialDate: draft.scheduleDate,
            completionHandler: didScheduleDraft
        )
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

        Task {
            await draftContentManager.saveCurrentDraftBody()
            dismissMessageView()
        }
    }

    private func didScheduleDraft(_ date: Date) {
        if let liveDraft = draft.thaw() {
            try? liveDraft.realm?.write {
                liveDraft.scheduleDate = date
                liveDraft.action = .schedule
            }
        }

        dismissMessageView()
    }

    private func didTouchSend() {
        if draft.encrypted && draft.encryptionPassword.isEmpty && !draft.autoEncryptDisabledRecipients.isEmpty {
            isShowingEncryptStatePanel = true
            return
        }

        guard !draft.subject.isEmpty else {
            matomo.track(eventWithCategory: .newMessage, name: "sendWithoutSubject")
            isShowingAlert = NewMessageAlert(type: .emptySubject(handler: sendDraft))
            return
        }

        let mailbox = mailboxManager.mailbox
        let mailboxIsFull = mailbox.quotas?.progression ?? 0 >= 1
        if mailboxIsFull,
           let pack = mailbox.pack,
           pack == .myKSuiteFree || pack == .kSuiteFree {
            matomo.track(eventWithCategory: .newMessage, name: "trySendingWithMailboxFull")
            Task {
                if let liveDraft = draft.thaw() {
                    try? liveDraft.realm?.write {
                        liveDraft.action = .save
                    }
                }
            }
            snackbarPresenter.show(
                message: MailResourcesStrings.Localizable.myKSuiteSpaceFullAlert,
                action: IKSnackBar.Action(title: MailResourcesStrings.Localizable.buttonUpgrade) {
                    if pack == .kSuiteFree {
                        mainViewState.isShowingKSuiteProUpgrade = true
                        matomo.track(eventWithCategory: .kSuiteProUpgradeBottomSheet, name: "notEnoughStorageUpgrade")
                    } else if pack == .myKSuiteFree {
                        mainViewState.isShowingMyKSuiteUpgrade = true
                        matomo.track(eventWithCategory: .myKSuiteUpgradeBottomSheet, name: "notEnoughStorageUpgrade")
                    }
                }
            )
            return
        }

        sendDraft()

        if !Bundle.main.isExtension && !platformDetector.isMac && !platformDetector.isRunningUITests {
            // We should implement a proper router to avoid doing this
            DispatchQueue.main.asyncAfter(deadline: UIConstants.modalCloseDelay) {
                mainViewState.isShowingSetAppAsDefaultDiscovery = UserDefaults.shared.shouldPresentSetAsDefaultDiscovery
            }
            if !mainViewState.isShowingSetAppAsDefaultDiscovery {
                mainViewState.isShowingChristmasEasterEgg = true
            }
        }
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
                liveDraft.action = draft.scheduleDate == nil ? .send : .schedule
            }
        }
        dismissMessageView()
    }

    private func changeSelectedFolder(to folder: Folder) {
        let freezeFolder = folder.freezeIfNeeded()
        mainViewState.selectedFolder = freezeFolder
    }
}

#Preview {
    ComposeMessageView(
        draft: Draft(),
        mailboxManager: PreviewHelper.sampleMailboxManager
    )
    .environmentObject(PreviewHelper.sampleMailboxManager)
}
