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
import MailCore
import MailCoreUI
import MailResources
import SwiftUI
import UIKit

enum EditorMobileToolbarStyle {
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

enum EditorToolbarAction: Int, Identifiable {
    case addFile
    case link
    case bold
    case underline
    case italic
    case strikeThrough
    case cancelFormat
    case unorderedList
    case editText
    case ai
    case addPhoto
    case takePhoto
    case programMessage

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
        case .addFile:
            return MailResourcesAsset.attachment
        case .addPhoto:
            return MailResourcesAsset.picture
        case .takePhoto:
            return MailResourcesAsset.photo
        case .link:
            return MailResourcesAsset.hyperlink
        case .programMessage:
            return MailResourcesAsset.alarmClock
        case .cancelFormat:
            return MailResourcesAsset.cancelFormat
        }
    }

    var tint: UIColor {
        if self == .ai {
            return MailResourcesAsset.aiColor.color
        } else {
            return MailResourcesAsset.textSecondaryColor.color
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
        case .programMessage:
            return "postpone"
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
        case .addFile:
            return MailResourcesStrings.Localizable.attachmentActionTitle
        case .addPhoto:
            return MailResourcesStrings.Localizable.attachmentActionPhotoLibrary
        case .takePhoto:
            return MailResourcesStrings.Localizable.buttonCamera
        case .link:
            return MailResourcesStrings.Localizable.buttonHyperlink
        case .programMessage:
            return MailResourcesStrings.Localizable.buttonSchedule
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
        case .editText, .ai, .addPhoto, .takePhoto, .programMessage, .cancelFormat:
            return nil
        }
    }

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
        case .editText, .ai, .addFile, .addPhoto, .takePhoto, .programMessage, .cancelFormat:
            return false
        }
    }

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
