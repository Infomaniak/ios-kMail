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
public typealias TextAttachment = (title: String?, body: String?)

/// Something that can provide a text to attach to content
public protocol TextAttachable {
    /// Async get the text
    var textAttachment: TextAttachment { get async }
}

extension NSItemProvider: TextAttachable {
    static let nilAttachment: TextAttachment = (nil, nil)

    public var textAttachment: TextAttachment {
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
