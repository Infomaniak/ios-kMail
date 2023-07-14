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
import RealmSwift
import SwiftUI

struct CreateFolderView: View {
    @EnvironmentObject private var mailboxManager: MailboxManager
    // swiftlint:disable:next empty_count
    @ObservedResults(Folder.self, where: { $0.parents.count == 0 }) private var folders

    @State private var folderName = ""
    @State private var error: FolderError?
    @State private var buttonIsEnabled = false

    @FocusState private var isFocused

    let mode: Mode

    enum Mode {
        case create
        case move(moveHandler: MoveEmailView.MoveHandler)

        var buttonTitle: String {
            switch self {
            case .create:
                return MailResourcesStrings.Localizable.buttonCreate
            case .move:
                return MailResourcesStrings.Localizable.newFolderDialogMovePositiveButton
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
        VStack(alignment: .leading) {
            Text(MailResourcesStrings.Localizable.newFolderDialogTitle)
                .textStyle(.bodyMedium)
                .padding(.bottom, 24)

            TextField(MailResourcesStrings.Localizable.createFolderName, text: $folderName)
                .onChange(of: folderName, perform: checkFolderName)
                .padding(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(error == nil ? MailResourcesAsset.textFieldBorder.swiftUIColor : MailResourcesAsset.redColor
                            .swiftUIColor)
                        .animation(.easeInOut, value: error)
                )
                .textStyle(.body)
                .focused($isFocused)

            Text(error?.localizedDescription ?? "None")
                .textStyle(.labelError)
                .padding(.top, 4)
                .opacity(error == nil ? 0 : 1)

            ModalButtonsView(primaryButtonTitle: mode.buttonTitle, primaryButtonEnabled: buttonIsEnabled) {
                @InjectService var matomo: MatomoUtils
                matomo.track(eventWithCategory: .createFolder, name: "confirm")
                Task {
                    await tryOrDisplayError {
                        let folder = try await mailboxManager.createFolder(name: folderName)
                        if case .move(let moveHandler) = mode {
                            moveHandler(folder)
                            NotificationCenter.default.post(Notification(name: .dismissMoveSheetNotificationName))
                        }
                    }
                }
            }
            .padding(.top, 24)
        }
        .onAppear {
            isFocused = true
        }
    }

    private func checkFolderName(_ newName: String) {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.count >= Constants.maxFolderNameLength {
            error = .nameTooLong
            // swiftlint:disable:next empty_count
        } else if trimmedName.lowercased() == "inbox" || folders.where({ $0.name == trimmedName }).count > 0 {
            error = .nameAlreadyExists
        } else {
            error = nil
        }

        buttonIsEnabled = !folderName.isEmpty && error == nil
    }
}

struct CreateFolderView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CreateFolderView(mode: .create)
            CreateFolderView(mode: .move { _ in /* Preview */ })
        }
        .environmentObject(PreviewHelper.sampleMailboxManager)
    }
}
