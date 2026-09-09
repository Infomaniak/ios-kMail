/*
 Infomaniak Mail - iOS App
 Copyright (C) 2026 Infomaniak Network SA

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

public struct RealmDebugArchiveBuilder {
    enum ArchiveError: Error {
        case noRealmFiles
    }

    public init() {}

    public func createArchive() async throws -> URL {
        let sourceDirectories = [
            ("mailboxes", MailboxManager.constants.rootDocumentsURL),
            ("contacts", ContactManager.constants.rootDocumentsURL)
        ]

        return try await createArchive(from: sourceDirectories)
    }

    @concurrent
    func createArchive(from sourceDirectories: [(name: String, url: URL)]) async throws -> URL {
        let fileManager = FileManager.default
        let stagingDirectory = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let archiveURL = fileManager.temporaryDirectory
            .appendingPathComponent("Infomaniak-Mail-Realms-\(UUID().uuidString)")
            .appendingPathExtension("zip")

        try fileManager.createDirectory(at: stagingDirectory, withIntermediateDirectories: true)
        defer {
            try? fileManager.removeItem(at: stagingDirectory)
        }

        var realmFileCount = 0
        for sourceDirectory in sourceDirectories where fileManager.fileExists(atPath: sourceDirectory.url.path) {
            let sourceURLs = try fileManager.contentsOfDirectory(
                at: sourceDirectory.url,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
            )
            let realmURLs = try sourceURLs.filter { url in
                guard url.pathExtension.lowercased() == "realm" else { return false }
                return try url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile == true
            }
            guard !realmURLs.isEmpty else { continue }

            let destinationDirectory = stagingDirectory
                .appendingPathComponent(sourceDirectory.name, isDirectory: true)
            try fileManager.createDirectory(at: destinationDirectory, withIntermediateDirectories: true)

            for realmURL in realmURLs {
                try fileManager.copyItem(
                    at: realmURL,
                    to: destinationDirectory.appendingPathComponent(realmURL.lastPathComponent)
                )
                realmFileCount += 1
            }
        }

        guard realmFileCount > 0 else {
            throw ArchiveError.noRealmFiles
        }

        var coordinationError: NSError?
        var archiveError: Error?
        NSFileCoordinator().coordinate(
            readingItemAt: stagingDirectory,
            options: .forUploading,
            error: &coordinationError
        ) { coordinatedURL in
            do {
                try fileManager.copyItem(at: coordinatedURL, to: archiveURL)
            } catch {
                archiveError = error
            }
        }

        if let coordinationError {
            throw coordinationError
        }
        if let archiveError {
            throw archiveError
        }

        return archiveURL
    }
}
