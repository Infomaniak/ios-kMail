/*
 Infomaniak Mail - iOS App
 Copyright (C) 2023 Infomaniak Network SA

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

import Combine
import Foundation
import InfomaniakCore
import InfomaniakCoreCommonUI
import PhotosUI
import UniformTypeIdentifiers

/// Interface of an Attachment
public protocol Attachable {
    var suggestedName: String? { get }
    var type: UTType? { get }
    func writeToTemporaryURL() async throws -> (url: URL, title: String?)
}

extension NSItemProvider: Attachable {
    enum ErrorDomain: Error {
        /// Not matching an UTI
        case UTINotFound

        /// The type needs dedicated handling
        case unsupportedUnderlyingType

        /// The item cannot be saved to a file
        case notWritableItem
    }

    private var preferredIdentifier: String {
        return registeredTypeIdentifiers
            .first { UTType($0)?.conforms(to: .image) == true || UTType($0)?.conforms(to: .movie) == true } ?? ""
    }

    public var type: UTType? {
        return UTType(preferredIdentifier)
    }

    public func writeToTemporaryURL() async throws -> (url: URL, title: String?) {
        switch underlyingType {
        case .isURL:
            let getPlist = try ItemProviderURLRepresentation(from: self)
            let result = try await getPlist.result.get()
            return (result.url, result.title)

        case .isText:
            let getText = try ItemProviderTextRepresentation(from: self)
            let resultURL = try await getText.result.get()
            return (resultURL, nil)

        case .isUIImage:
            let getUIImage = try ItemProviderUIImageRepresentation(from: self)
            let resultURL = try await getUIImage.result.get()
            return (resultURL, nil)

        case .isImageData, .isCompressedData, .isMiscellaneous:
            let getFile = try ItemProviderFileRepresentation(from: self)
            let result = try await getFile.result.get()
            return (result.url, result.title)

        case .isDirectory:
            let getFile = try ItemProviderZipRepresentation(from: self)
            let result = try await getFile.result.get()
            return (result.url, result.title)

        case .isPropertyList:
            throw ErrorDomain.notWritableItem

        case .none:
            throw ErrorDomain.UTINotFound

        // Keep it for forward compatibility
        default:
            throw ErrorDomain.unsupportedUnderlyingType
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

    public func writeToTemporaryURL() async throws -> (url: URL, title: String?) {
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

    public func writeToTemporaryURL() async throws -> (url: URL, title: String?) {
        return (self, nil)
    }
}

extension Data: Attachable {
    public var suggestedName: String? {
        return nil
    }

    public var type: UTType? {
        return UTType.image
    }

    public func writeToTemporaryURL() async throws -> (url: URL, title: String?) {
        let temporaryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let temporaryFileURL = temporaryURL.appendingPathComponent("attachment").appendingPathExtension("jpeg")
        try FileManager.default.createDirectory(at: temporaryURL, withIntermediateDirectories: true)
        try write(to: temporaryFileURL)
        return (temporaryFileURL, nil)
    }
}
