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

import Foundation
import MailResources
import PDFKit
import QuickLookThumbnailing
import SwiftUI
import UniformTypeIdentifiers

public struct AttachmentHelper: Sendable {
    public let type: String
    public let fileExtension: String?

    public init(type: String, fileExtension: String? = nil) {
        self.type = type
        self.fileExtension = fileExtension
    }

    public var icon: MailResourcesImages {
        if let utiFromType = UTType(mimeType: type, conformingTo: .data),
           let icon = guessIcon(forUTType: utiFromType) {
            return icon
        }

        if let fileExtension,
           let utiFromExtension = UTType(filenameExtension: fileExtension),
           let icon = guessIcon(forUTType: utiFromExtension) {
            return icon
        }

        return MailResourcesAsset.unknownFile
    }

    private func guessIcon(forUTType uti: UTType) -> MailResourcesImages? {
        if uti.conforms(to: .pdf) {
            return MailResourcesAsset.pdfFile
        }
        if uti.conforms(to: .calendarEvent) || uti.conforms(to: .ics) {
            return MailResourcesAsset.icsFile
        }
        if uti.conforms(to: .vCard) {
            return MailResourcesAsset.vcardFile
        }
        if uti.conforms(to: .image) {
            return MailResourcesAsset.imageFile
        }
        if uti.conforms(to: .audio) {
            return MailResourcesAsset.audioFile
        }
        if uti.conforms(to: .movie) {
            return MailResourcesAsset.videoFile
        }
        if uti.conforms(to: .spreadsheet) {
            return MailResourcesAsset.gridFile
        }
        if uti.conforms(to: .presentation) {
            return MailResourcesAsset.pointFile
        }
        if uti.conforms(to: .sourceCode) || uti.conforms(to: .html) || uti.conforms(to: .json) || uti.conforms(to: .xml) {
            return MailResourcesAsset.codeFile
        }
        if uti.conforms(to: .text) || uti.conforms(to: .pages) || uti.conforms(to: .onlyOffice)
            || uti.conforms(to: .wordDoc) || uti.conforms(to: .wordDocm) || uti.conforms(to: .wordDocx) {
            return MailResourcesAsset.docFile
        }
        if uti.conforms(to: .archive) {
            return MailResourcesAsset.archiveFile
        }
        if uti.conforms(to: .font) {
            return MailResourcesAsset.fontFile
        }
        return nil
    }
}
