/*
 Infomaniak Mail - iOS App
 Copyright (C) 2025 Infomaniak Network SA

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

import AppIntents
import Foundation

@available(iOS 18.4, *)
extension IntentFile: Attachable {
    public var suggestedName: String? {
        filename
    }

    public func writeToTemporaryURL() async throws -> (url: URL, title: String?) {
        if let fileURL {
            return try await fileURL.writeToTemporaryURL()
        } else {
            let temporaryDirectoryURL = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
            try FileManager.default.createDirectory(at: temporaryDirectoryURL, withIntermediateDirectories: true)
            let temporaryURL = temporaryDirectoryURL.appending(path: filename.safeLastPathComponent ?? UUID().uuidString)
            try data.write(to: temporaryURL)
            return (temporaryURL, filename)
        }
    }
}
