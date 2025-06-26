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
import InfomaniakRichHTMLEditor
import MailCoreUI
import MailResources
import SwiftUI

enum EditorToolbarAction: Identifiable {
    case link
    case bold
    case underline
    case italic
    case strikeThrough
    case cancelFormat
    case unorderedList
    case editText
    case ai
    case addAttachment
    case addFile
    case addPhoto
    case takePhoto

    var id: Self { self }

    var icon: MailResourcesImages {
        switch self {
        case .bold:
            return MailResourcesAsset.bold
        case .italic:
            return MailResourcesAsset.italic
        case .underline:
            return MailResourcesAsset.underline
        case .strikeThrough:
            return MailResourcesAsset.strikeThrough
        case .unorderedList:
            return MailResourcesAsset.list
        case .editText:
            return MailResourcesAsset.textModes
        case .ai:
            return MailResourcesAsset.aiWriter
        case .addAttachment:
            return MailResourcesAsset.attachment
        case .addFile:
            return MailResourcesAsset.attachment
        case .addPhoto:
            return MailResourcesAsset.picture
        case .takePhoto:
            return MailResourcesAsset.photo
        case .link:
            return MailResourcesAsset.hyperlink
        case .cancelFormat:
            return MailResourcesAsset.cancelFormat
        }
    }

    var tint: Color {
        if self == .ai {
            return MailResourcesAsset.aiColor.swiftUIColor
        } else {
            return MailResourcesAsset.textSecondaryColor.swiftUIColor
        }
    }

    var foregroundStyle: Color {
        if self == .ai {
            return MailResourcesAsset.aiColor.swiftUIColor
        } else {
            return MailResourcesAsset.toolbarForegroundColor.swiftUIColor
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
        default:
            return nil
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .bold:
            return MailResourcesStrings.Localizable.buttonBold
        case .italic:
            return MailResourcesStrings.Localizable.buttonItalic
        case .underline:
            return MailResourcesStrings.Localizable.buttonUnderline
        case .strikeThrough:
            return MailResourcesStrings.Localizable.buttonStrikeThrough
        case .unorderedList:
            return MailResourcesStrings.Localizable.buttonUnorderedList
        case .editText:
            return MailResourcesStrings.Localizable.buttonEditText
        case .ai:
            return MailResourcesStrings.Localizable.aiDiscoveryTitle
        case .addAttachment:
            return "!Add Attachment"
        case .addFile:
            return MailResourcesStrings.Localizable.attachmentActionTitle
        case .addPhoto:
            return MailResourcesStrings.Localizable.attachmentActionPhotoLibrary
        case .takePhoto:
            return MailResourcesStrings.Localizable.buttonCamera
        case .link:
            return MailResourcesStrings.Localizable.buttonHyperlink
        case .cancelFormat:
            return MailResourcesStrings.Localizable.buttonCancelFormatting
        }
    }

    var keyboardShortcut: KeyboardShortcut? {
        switch self {
        case .bold:
            return KeyboardShortcut("B", modifiers: [.command, .shift])
        case .italic:
            return KeyboardShortcut("I", modifiers: [.command, .shift])
        case .underline:
            return KeyboardShortcut("U", modifiers: [.command, .shift])
        case .strikeThrough:
            return KeyboardShortcut("X", modifiers: [.command, .shift])
        case .unorderedList:
            return KeyboardShortcut("L", modifiers: [.command, .shift])
        case .link:
            return KeyboardShortcut("K", modifiers: [.command, .shift])
        case .addFile:
            return KeyboardShortcut("P", modifiers: [.command, .shift])
        case .editText, .ai, .addAttachment, .addPhoto, .takePhoto, .cancelFormat:
            return nil
        }
    }

    @MainActor
    func isSelected(textAttributes: TextAttributes) -> Bool {
        switch self {
        case .bold:
            return textAttributes.hasBold
        case .italic:
            return textAttributes.hasItalic
        case .underline:
            return textAttributes.hasUnderline
        case .strikeThrough:
            return textAttributes.hasStrikethrough
        case .unorderedList:
            return textAttributes.hasUnorderedList
        case .link:
            return textAttributes.hasLink
        case .editText, .ai, .addAttachment, .addFile, .addPhoto, .takePhoto, .cancelFormat:
            return false
        }
    }

    @MainActor
    func action(
        textAttributes: TextAttributes,
        isShowingLinkAlert: Binding<Bool>,
        isShowingFileSelection: Binding<Bool>,
        isShowingAI: Binding<Bool>
    ) {
        switch self {
        case .bold:
            textAttributes.bold()
        case .underline:
            textAttributes.underline()
        case .italic:
            textAttributes.italic()
        case .strikeThrough:
            textAttributes.strikethrough()
        case .cancelFormat:
            textAttributes.removeFormat()
        case .unorderedList:
            textAttributes.unorderedList()
        case .link:
            guard !textAttributes.hasLink else {
                return textAttributes.unlink()
            }
            isShowingLinkAlert.wrappedValue = true
        case .addFile:
            isShowingFileSelection.wrappedValue = true
        case .ai:
            isShowingAI.wrappedValue = true
        default:
            return
        }
    }
}
