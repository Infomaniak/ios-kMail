/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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
import InfomaniakRichEditor
import MailCore
import MailCoreUI
import MailResources
import SwiftModalPresentation
import UIKit

final class EditorToolbarModel: ObservableObject {
    @ModalPublished(context: ContextKeys.compose) var isShowingCamera = false
    @ModalPublished(context: ContextKeys.compose) var isShowingFileSelection = false
    @ModalPublished(context: ContextKeys.compose) var isShowingPhotoLibrary = false
    @ModalPublished(context: ContextKeys.compose) var isShowingLinkAlert = false
}

enum EditorToolbarStyle {
    case main
    case textEdition

    var actions: [EditorToolbarAction] {
        switch self {
        case .main:
            @InjectService var featureFlagsManageable: FeatureFlagsManageable
            var mainActions: [EditorToolbarAction] = [.editText, .addFile, .addPhoto, .takePhoto, .link]
            featureFlagsManageable.feature(.aiMailComposer, on: {
                mainActions.insert(.ai, at: 1)
            }, off: nil)
            return mainActions
        case .textEdition:
            return [.editText, .bold, .italic, .underline, .strikeThrough, .unorderedList]
        }
    }
}

enum EditorToolbarAction: Int {
    case bold = 1
    case italic
    case underline
    case strikeThrough
    case unorderedList
    case editText
    case ai
    case addFile
    case addPhoto
    case takePhoto
    case link
    case programMessage

    var icon: UIImage {
        switch self {
        case .bold:
            return MailResourcesAsset.bold.image
        case .italic:
            return MailResourcesAsset.italic.image
        case .underline:
            return MailResourcesAsset.underline.image
        case .strikeThrough:
            return MailResourcesAsset.strikeThrough.image
        case .unorderedList:
            return MailResourcesAsset.unorderedList.image
        case .editText:
            return MailResourcesAsset.textModes.image
        case .ai:
            return MailResourcesAsset.aiWriter.image
        case .addFile:
            return MailResourcesAsset.folder.image
        case .addPhoto:
            return MailResourcesAsset.pictureLandscape.image
        case .takePhoto:
            return MailResourcesAsset.photo.image
        case .link:
            return MailResourcesAsset.hyperlink.image
        case .programMessage:
            return MailResourcesAsset.waitingMessage.image
        }
    }

    var tint: UIColor {
        if self == .ai {
            return MailResourcesAsset.aiColor.color
        } else {
            return MailResourcesAsset.textSecondaryColor.color
        }
    }

    var matomoName: String? {
        switch self {
        case .bold:
            return "bold"
        case .italic:
            return "italic"
        case .underline:
            return "underline"
        case .strikeThrough:
            return "strikeThrough"
        case .unorderedList:
            return "unorderedList"
        case .ai:
            return "aiWriter"
        case .addFile:
            return "importFile"
        case .addPhoto:
            return "importImage"
        case .takePhoto:
            return "importFromCamera"
        case .link:
            return "addLink"
        case .programMessage:
            return "postpone"
        default:
            return nil
        }
    }

    func isSelected(textAttributes: RETextAttributes) -> Bool {
        switch self {
        case .bold:
            return textAttributes.format.hasBold
        case .italic:
            return textAttributes.format.hasItalic
        case .underline:
            return textAttributes.format.hasUnderline
        case .strikeThrough:
            return textAttributes.format.hasStrikeThrough
        case .link:
            return false
        case .unorderedList, .editText, .ai, .addFile, .addPhoto, .takePhoto, .programMessage:
            return false
        }
    }
}
