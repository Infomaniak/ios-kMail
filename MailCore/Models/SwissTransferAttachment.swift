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

import Foundation
import RealmSwift
// TODO: To remove
import MailResources
import PDFKit
import QuickLookThumbnailing
import SwiftUI
import UniformTypeIdentifiers

public class SwissTransferAttachment: EmbeddedObject, Codable {
    @Persisted public var uuid: String
    @Persisted public var nbfiles: Int
    @Persisted public var size: Int64
    @Persisted public var files: RealmSwift.List<File>
}

public class File: EmbeddedObject, Codable, Identifiable {
    @Persisted public var uuid: String
    @Persisted public var name: String
    @Persisted public var size: Int64
    @Persisted public var type: String

    // TODO: To Remove: duplication
    public var uti: UTType? {
        UTType(mimeType: type, conformingTo: .data)
    }

    public var icon: MailResourcesImages {
        guard let uti else { return MailResourcesAsset.unknownFile }

        if uti.conforms(to: .pdf) {
            return MailResourcesAsset.pdfFile
        } else if uti.conforms(to: .calendarEvent) || uti.conforms(to: .ics) {
            return MailResourcesAsset.icsFile
        } else if uti.conforms(to: .vCard) {
            return MailResourcesAsset.vcardFile
        } else if uti.conforms(to: .image) {
            return MailResourcesAsset.imageFile
        } else if uti.conforms(to: .audio) {
            return MailResourcesAsset.audioFile
        } else if uti.conforms(to: .movie) {
            return MailResourcesAsset.videoFile
        } else if uti.conforms(to: .spreadsheet) {
            return MailResourcesAsset.gridFile
        } else if uti.conforms(to: .presentation) {
            return MailResourcesAsset.pointFile
        } else if uti.conforms(to: .sourceCode) || uti.conforms(to: .html) || uti.conforms(to: .json) || uti.conforms(to: .xml) {
            return MailResourcesAsset.codeFile
        } else if uti.conforms(to: .text) || uti.conforms(to: .pages) || uti.conforms(to: .onlyOffice)
            || uti.conforms(to: .wordDoc) || uti.conforms(to: .wordDocm) || uti.conforms(to: .wordDocx) {
            return MailResourcesAsset.docFile
        } else if uti.conforms(to: .archive) {
            return MailResourcesAsset.archiveFile
        } else if uti.conforms(to: .font) {
            return MailResourcesAsset.fontFile
        } else {
            return MailResourcesAsset.unknownFile
        }
    }
}
