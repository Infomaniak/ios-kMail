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
import InfomaniakCoreUI
import MailCore
import PhotosUI
import UniformTypeIdentifiers

extension NSItemProvider: Attachable {
    enum ErrorDomain: Error {
        case UTINotFound
    }

    private var preferredIdentifier: String {
        return registeredTypeIdentifiers
            .first { UTType($0)?.conforms(to: .image) == true || UTType($0)?.conforms(to: .movie) == true } ?? ""
    }

    public var type: UTType? {
        return UTType(preferredIdentifier)
    }

    public func writeToTemporaryURL() async throws -> URL {
        switch underlyingType {
        case .isURL:
            let getPlist = try ItemProviderURLRepresentation(from: self)
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

        case .none:
            throw ErrorDomain.UTINotFound
        }
    }
}

extension PHPickerResult: Attachable {
    public var suggestedName: String? {
        return itemProvider.suggestedName
    }

    public var type: UTType? {
        return itemProvider.type
    }

    public func writeToTemporaryURL() async throws -> URL {
        return try await itemProvider.writeToTemporaryURL()
    }
}

extension URL: Attachable {
    public var suggestedName: String? {
        return lastPathComponent
    }

    public var type: UTType? {
        return UTType.data
    }

    public func writeToTemporaryURL() async throws -> URL {
        return self
    }
}

extension Data: Attachable {
    public var suggestedName: String? {
        return nil
    }

    public var type: UTType? {
        return UTType.image
    }

    public func writeToTemporaryURL() async throws -> URL {
        let temporaryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let temporaryFileURL = temporaryURL.appendingPathComponent("attachment").appendingPathExtension("jpeg")
        try FileManager.default.createDirectory(at: temporaryURL, withIntermediateDirectories: true)
        try write(to: temporaryFileURL)
        return temporaryFileURL
    }
}
