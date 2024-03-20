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
import InfomaniakCore

/// Tuple wrapping an abstract title and body
typealias TextAttachment = (title: String?, body: String?)

/// Something that can provide a text to attach to content
protocol TextAttachable {
    /// Async get the text
    var textAttachment: TextAttachment { get async }
}

extension NSItemProvider: TextAttachable {
    static let nilAttachment: TextAttachment = (nil, nil)

    var textAttachment: TextAttachment {
        get async {
            guard underlyingType == .isPropertyList else {
                return Self.nilAttachment
            }

            let propertyValueRepresentation = ItemProviderPropertyValueRepresentation(from: self)
            do {
                let rootDictionary = try await propertyValueRepresentation.result.get()

                // In this app the only supported .propertyList ItemProvider is the result from JS computation within Safari.
                guard let dictionary = rootDictionary[NSExtensionJavaScriptPreprocessingResultsKey] as? NSDictionary else {
                    print("not a NSExtensionJavaScriptPreprocessingResultsKey")
                    return Self.nilAttachment
                }

                let resultTuple = (dictionary["title"] as? String, dictionary["URL"] as? String)
                return resultTuple
            } catch {
                print("error:\(error)")
                return Self.nilAttachment
            }
        }
    }
}

// TODO: Move to core
/// Something that can provide a `Progress` and an async `Result` in order to make a Dictionary from a `NSItemProvider`
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public final class ItemProviderPropertyValueRepresentation: NSObject, ProgressResultable {
    /// Progress increment size
    private static let progressStep: Int64 = 1

    /// Number of steps to complete the task
    private static let totalSteps: Int64 = 1

    /// Something to transform events to a nice `async Result`
    private let flowToAsync = FlowToAsyncResult<Success>()

    private let itemProvider: NSItemProvider

    /// Domain specific errors
    public enum ErrorDomain: Error, Equatable {
        /// loadItem cast failed
        case unableToReadDictionary
    }

    public typealias Success = NSDictionary
    public typealias Failure = Error

    public init(from itemProvider: NSItemProvider) {
        progress = Progress(totalUnitCount: Self.totalSteps)

        self.itemProvider = itemProvider
        super.init()

        Task {
            let completionProgress = Progress(totalUnitCount: Self.totalSteps)
            progress.addChild(completionProgress, withPendingUnitCount: Self.progressStep)

            defer {
                completionProgress.completedUnitCount += Self.progressStep
            }

            let propertyListIdentifier = UTI.propertyList.identifier
            if self.itemProvider.hasItemConformingToTypeIdentifier(propertyListIdentifier) {
                guard let resultDictionary = try await self.itemProvider
                    .loadItem(forTypeIdentifier: propertyListIdentifier) as? NSDictionary else {
                    flowToAsync.sendFailure(ErrorDomain.unableToReadDictionary)
                    return
                }

                flowToAsync.sendSuccess(resultDictionary)

            } else {
                flowToAsync.sendFailure(ErrorDomain.unableToReadDictionary)
            }
        }
    }

    // MARK: ProgressResultable

    public var progress: Progress

    public var result: Result<Success, Failure> {
        get async {
            return await flowToAsync.result
        }
    }
}
