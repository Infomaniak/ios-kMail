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

import CocoaLumberjackSwift
import InfomaniakCore
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailResources
import RealmSwift
import Shimmer
import SwiftUI

// TODO: Move to core
extension Task {
    @discardableResult
    func finish() async -> Result<Success, Failure> {
        await result
    }
}

// TODO: Move to core
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public actor ArrayAccumulator<T> {
    /// Local Error Domain
    public enum ErrorDomain: Error {
        case outOfBounds
    }

    /// A buffer array
    private var buffer: [T?]

    /// Init an ArrayAccumulator
    /// - Parameters:
    ///   - count: The count of items in the accumulator
    ///   - wrapping: The type of the content wrapped in an array
    public init(count: Int, wrapping: T.Type) {
        buffer = [T?](repeating: nil, count: count)
    }

    /// Set an item at a specified index
    /// - Parameters:
    ///   - item: the item to be stored
    ///   - index: The index where we store the item
    public func set(item: T?, atIndex index: Int) throws {
        guard index < buffer.count else {
            throw ErrorDomain.outOfBounds
        }
        buffer[index] = item
    }

    /// The accumulated ordered nullable content at the time of calling
    /// - Returns: The ordered nullable content at the time of calling
    public var accumulation: [T?] {
        return buffer
    }

    /// The accumulated ordered result at the time of calling. Nil values are removed.
    /// - Returns: The ordered result at the time of calling. Nil values are removed.
    public var compactAccumulation: [T] {
        return buffer.compactMap { $0 }
    }
}

// TODO: Move to core
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public struct ParallelTaskMapper {
    /// internal processing TaskQueue
    let taskQueue: TaskQueue

    /// Init function
    /// - Parameter concurrency: execution depth, keep default for optimized threading.
    public init(concurrency: Int = max(4, ProcessInfo.processInfo.activeProcessorCount) /* parallel by default */ ) {
        assert(concurrency > 0, "zero concurrency locks execution")
        print("concurrency = \(concurrency)")
        taskQueue = TaskQueue(concurrency: concurrency)
    }

    /// Map a task to a collection of items
    ///
    /// With this, you can easily _parallelize_  *async/await* code.
    ///
    /// This is using an underlying `TaskQueue` (with an optimized queue depth)
    /// Using it to apply work to each item of a given collection.
    /// - Parameters:
    ///   - collection: The input collection of items to be processed
    ///   - toOperation: The operation to be applied to the `collection` of items
    /// - Returns: An ordered processed collection of the desired type
    public func map<T, U>(collection: [U],
                          toOperation operation: @escaping @Sendable (_ item: U) async throws -> T?) async throws -> [T?] {
        // Using an ArrayAccumulator to preserve the order of results
        let accumulator = ArrayAccumulator(count: collection.count, wrapping: T.self)

        // Using a TaskGroup to track completion
        _ = try await withThrowingTaskGroup(of: Void.self, returning: Void.self) { taskGroup in
            for (index, item) in collection.enumerated() {
                taskGroup.addTask {
                    let result = try await self.taskQueue.enqueue {
                        try await operation(item)
                    }

                    try? await accumulator.set(item: result, atIndex: index)
                }
            }

            // await completion of all tasks
            try await taskGroup.waitForAll()
        }

        // Get the accumulated results
        let accumulated = await accumulator.accumulation
        return accumulated
    }
}

struct MessageView: View {
    @ObservedRealmObject var message: Message
    @State var presentableBody: PresentableBody
    @EnvironmentObject var mailboxManager: MailboxManager
    @State var isHeaderExpanded = false
    @State var isMessageExpanded: Bool

    /// True once we finished preprocessing the content
    @State var isMessagePreprocessed = false

    /// The cancellable task used to preprocess the content
    @State var preprocessing: Task<Void, Never>?

    @LazyInjectService var matomo: MatomoUtils

    init(message: Message, isMessageExpanded: Bool = false) {
        self.message = message
        presentableBody = PresentableBody(message: message)
        self.isMessageExpanded = isMessageExpanded
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                MessageHeaderView(
                    message: message,
                    isHeaderExpanded: $isHeaderExpanded,
                    isMessageExpanded: $isMessageExpanded
                )
                .padding(.horizontal, 16)

                if isMessageExpanded {
                    if !message.attachments.filter({ $0.disposition == .attachment || $0.contentId == nil }).isEmpty {
                        AttachmentsView(message: message)
                            .padding(.top, 24)
                    }
                    MessageBodyView(presentableBody: $presentableBody, messageUid: message.uid)
                        .padding(.top, 16)
                }
            }
            .padding(.vertical, 16)
            .task {
                if self.message.shouldComplete {
                    await fetchMessage()
                }
            }
            .onChange(of: message.fullyDownloaded) { _ in
                if message.fullyDownloaded, isMessageExpanded {
                    prepareBodyIfNeeded()
                }
            }
            .onChange(of: isMessageExpanded) { _ in
                if message.fullyDownloaded, isMessageExpanded {
                    prepareBodyIfNeeded()
                } else {
                    cancelPrepareBodyIfNeeded()
                }
            }
            .onAppear {
                if message.fullyDownloaded,
                   isMessageExpanded,
                   !isMessagePreprocessed,
                   preprocessing == nil {
                    prepareBodyIfNeeded()
                }
            }
            .onDisappear {
                cancelPrepareBodyIfNeeded()
            }
        }
    }

    @MainActor private func fetchMessage() async {
        await tryOrDisplayError {
            try await mailboxManager.message(message: message)
        }
    }

    /// Update the DOM in the main actor
    @MainActor func mutate(compactBody: String?, quote: String?) {
        presentableBody.compactBody = compactBody
        presentableBody.quote = quote
    }

    /// Update the DOM in the main actor
    @MainActor func mutate(body: String?, compactBody: String?) {
        presentableBody.body?.value = body
        presentableBody.compactBody = compactBody
    }

    /// preprocess is finished
    @MainActor func processingCompleted() {
        print("••processingCompleted")
        isMessagePreprocessed = true
    }
}

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MessageView(message: PreviewHelper.sampleMessage)

            MessageView(message: PreviewHelper.sampleMessage, isMessageExpanded: true)
        }
        .previewLayout(.sizeThatFits)
    }
}
