/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

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
import MailCore
import MailCoreUI
import MailResources
import RealmSwift
import SwiftUI

struct CreateFolderView: View {
    @LazyInjectService private var matomo: MatomoUtils

    @EnvironmentObject private var mailboxManager: MailboxManager

    @Environment(\.dismiss) private var dismiss
    // swiftlint:disable:next empty_count
    @ObservedResults(Folder.self, where: { $0.parents.count == 0 }) private var folders

    @State private var folderName = ""
    @State private var error: FolderError?

    @FocusState private var isFocused

    let mode: Mode
    let folder: Folder?

    private var isButtonEnabled: Bool {
        return !folderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && error == nil
    }

    enum Mode {
        case create
        case move(moveHandler: MoveEmailView.MoveHandler)
        case modify

        var buttonTitle: String {
            switch self {
            case .create:
                return MailResourcesStrings.Localizable.buttonCreate
            case .move:
                return MailResourcesStrings.Localizable.newFolderDialogMovePositiveButton
            case .modify:
                return MailResourcesStrings.Localizable.buttonValid
            }
        }
    }

    private enum FolderError: Error, LocalizedError {
        case nameTooLong
        case nameAlreadyExists

        var errorDescription: String? {
            switch self {
            case .nameTooLong:
                return MailResourcesStrings.Localizable.errorNewFolderNameTooLong
            case .nameAlreadyExists:
                return MailResourcesStrings.Localizable.errorNewFolderAlreadyExists
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(MailResourcesStrings.Localizable.newFolderDialogTitle)
                .textStyle(.bodyMedium)
                .padding(.bottom, IKPadding.alertTitleBottom)

            TextField(MailResourcesStrings.Localizable.createFolderName, text: $folderName)
                .onChange(of: folderName, perform: checkFolderName)
                .padding(value: .small)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(error == nil ? MailResourcesAsset.textFieldBorder.swiftUIColor : MailResourcesAsset.redColor
                            .swiftUIColor)
                        .animation(.easeInOut, value: error)
                )
                .textStyle(.body)
                .focused($isFocused)

            Text(error?.errorDescription ?? "")
                .textStyle(.labelError)
                .padding(.top, value: .micro)
                .opacity(error == nil ? 0 : 1)
                .padding(.bottom, value: .mini)

            ModalButtonsView(primaryButtonTitle: mode.buttonTitle, primaryButtonEnabled: isButtonEnabled) {
                switch mode {
                case .modify:
                    if folder != nil {
                        await tryOrDisplayError {
                            let folder = try await mailboxManager.modifyFolder(
                                name: folderName,
                                folder: folder!
                            )
                        }
                    }
                default:
                    await tryOrDisplayError {
                        matomo.track(eventWithCategory: .createFolder, name: "confirm")
                        let folder = try await mailboxManager.createFolder(name: folderName, parent: nil)
                        if case .move(let moveHandler) = mode {
                            moveHandler(folder)
                            NotificationCenter.default.post(Notification(name: .dismissMoveSheet))
                        }
                    }
                }
            }
        }
        .onAppear {
            isFocused = true
        }
        .accessibilityAction(.escape) {
            dismiss()
        }
    }

    private func checkFolderName(_ newName: String) {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            withAnimation { error = nil }
            return
        }

        withAnimation {
            if trimmedName.count >= Constants.maxFolderNameLength {
                error = .nameTooLong
            } else if trimmedName.lowercased() == "inbox" || !folders.where({ $0.name == trimmedName }).isEmpty {
                error = .nameAlreadyExists
            } else {
                error = nil
            }
        }
    }
}

#Preview {
    Group {
        CreateFolderView(mode: .create, folder: nil)
        CreateFolderView(mode: .move { _ in /* Preview */ }, folder: nil)
    }
    .environmentObject(PreviewHelper.sampleMailboxManager)
}
