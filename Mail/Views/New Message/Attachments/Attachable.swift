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

import Combine
import Foundation
import InfomaniakCore
import MailCore
import PhotosUI
import UniformTypeIdentifiers

protocol Attachable {
    var suggestedName: String? { get }
    var type: UTType? { get }
    func writeToTemporaryURL() async throws -> URL
}

extension NSItemProvider: Attachable {
    enum ErrorDomain: Error {
        case UTINotFound
    }

    private var preferredIdentifier: String {
        return registeredTypeIdentifiers
            .first { UTType($0)?.conforms(to: .image) == true || UTType($0)?.conforms(to: .movie) == true } ?? ""
    }

    var type: UTType? {
        return UTType(preferredIdentifier)
    }

    func writeToTemporaryURL() async throws -> URL {
        switch underlyingType {
        case .isURL:
            let getPlist = try ItemProviderWeblocRepresentation(from: self)
            return try await getPlist.result.get()

        case .isText:
            let getText = try ItemProviderTextRepresentation(from: self)
            return try await getText.result.get()

        case .isUIImage:
            let getUIImage = try ItemProviderUIImageRepresentation(from: self)
            return try await getUIImage.result.get()

        case .isImageData, .isCompressedData, .isMiscellaneous:
            let getFile = try ItemProviderFileRepresentation(from: self)
            return try await getFile.result.get()

        case .isDirectory:
            let getFile = try ItemProviderZipRepresentation(from: self)
            return try await getFile.result.get()

            // TODO: remove from core
//            let url = try await zippedRepresentation.get()
//            return url

        case .none:
            throw ErrorDomain.UTINotFound
        }
    }
}

extension PHPickerResult: Attachable {
    var suggestedName: String? {
        return itemProvider.suggestedName
    }

    var type: UTType? {
        return itemProvider.type
    }

    func writeToTemporaryURL() async throws -> URL {
        return try await itemProvider.writeToTemporaryURL()
    }
}

extension URL: Attachable {
    var suggestedName: String? {
        return lastPathComponent
    }

    var type: UTType? {
        return UTType.data
    }

    func writeToTemporaryURL() async throws -> URL {
        return self
    }
}

extension Data: Attachable {
    var suggestedName: String? {
        return nil
    }

    var type: UTType? {
        return UTType.image
    }

    func writeToTemporaryURL() async throws -> URL {
        let temporaryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let temporaryFileURL = temporaryURL.appendingPathComponent("attachment").appendingPathExtension("jpeg")
        try FileManager.default.createDirectory(at: temporaryURL, withIntermediateDirectories: true)
        try write(to: temporaryFileURL)
        return temporaryFileURL
    }
}
