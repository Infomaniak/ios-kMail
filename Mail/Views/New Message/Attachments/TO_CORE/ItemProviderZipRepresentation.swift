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
import InfomaniakDI

/// Something that can provide a `Progress` and an async `Result` in order to make a zip from a `NSItemProvider`
final class ItemProviderZipRepresentation: NSObject, ProgressResultable {
    enum ErrorDomain: Error {
        case UTINotFound
        case unableToBuildTempURL
        case unableToLoadURLForObject
    }

    typealias Success = URL
    typealias Failure = Error

    private static let progressStep: Int64 = 1
    
    /// Track task progress with internal Combine pipe
    private let resultProcessed = PassthroughSubject<Success, Failure>()

    /// Internal observation of the Combine progress Pipe
    private var resultProcessedObserver: AnyCancellable?

    /// Internal Task that wraps the combine result observation
    private var computeResultTask: Task<Success, Failure>?

    public init(from itemProvider: NSItemProvider) throws {
        // Keep compiler happy
        progress = Progress(totalUnitCount: 1)

        super.init()

        let fileManager = FileManager.default
        let coordinator = NSFileCoordinator()

        progress = itemProvider.loadObject(ofClass: URL.self) { path, error in
            guard error == nil, let path: URL = path else {
                let error: Error = error ?? ErrorDomain.unableToLoadURLForObject
                self.resultProcessed.send(completion: .failure(error))
                return
            }

            // Get a NSProgress on file copy is hard ~>
            // https://developer.apple.com/forums/thread/114001?answerId=350635022#350635022
            // > If you’d like to see such support [ie. for NSProgress] added in the future, I encourage you to file an
            // enhancement request

            // Minimalist progress file processing support
            let childProgress = Progress()
            self.progress.addChild(childProgress, withPendingUnitCount: Self.progressStep)

            // compress content of folder and move it somewhere we can safely store it for upload
            var error: NSError?
            coordinator.coordinate(readingItemAt: path, options: [.forUploading], error: &error) { zipURL in
                @InjectService var pathProvider: AppGroupPathProvidable
                let tmpDirectoryURL = pathProvider.tmpDirectoryURL
                let fileName = path.lastPathComponent
                let tempURL = tmpDirectoryURL.appendingPathComponent("\(fileName).zip")

                do {
                    try fileManager.moveItem(at: zipURL, to: tempURL)
                    self.resultProcessed.send(tempURL)
                    self.resultProcessed.send(completion: .finished)
                } catch {
                    self.resultProcessed.send(completion: .failure(error))
                }
                childProgress.completedUnitCount += Self.progressStep
            }
        }

        /// Wrap the Combine pipe to a native Swift Async Task for convenience
        computeResultTask = Task {
            do {
                let result: URL = try await withCheckedThrowingContinuation { continuation in
                    self.resultProcessedObserver = resultProcessed.sink { result in
                        switch result {
                        case .finished:
                            break
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                        self.resultProcessedObserver?.cancel()
                    } receiveValue: { value in
                        continuation.resume(with: .success(value))
                    }
                }

                return result

            } catch {
                throw error
            }
        }
    }

    // MARK: Public

    var progress: Progress

    var result: Result<URL, Error> {
        get async {
            guard let computeResultTask else {
                fatalError("This never should be nil")
            }

            return await computeResultTask.result
        }
    }
}
