/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

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
import RealmSwift

public enum SignaturePosition: String, PersistableEnum, Codable {
    case beforeReplyMessage = "top"
    case afterReplyMessage = "bottom"
}

public struct SignatureResponse: Decodable {
    public var signatures: [Signature]
    public var defaultSignatureId: Int?
    public var defaultReplySignatureId: Int?

    public var `default`: Signature? {
        signatures.first(where: \.isDefault)
    }

    private enum CodingKeys: String, CodingKey {
        case signatures
        case defaultSignatureId
        case defaultReplySignatureId
    }
}

public final class Signature: Object, Codable, Identifiable {
    @Persisted(primaryKey: true) public var id: Int
    @Persisted public var name: String
    @Persisted public var content: String
    @Persisted public var senderName: String
    @Persisted public var senderEmail: String
    @Persisted public var senderEmailIdn: String
    @Persisted public var isDefault: Bool
    @Persisted public var isDefaultReply = false
    @Persisted public var position: SignaturePosition

    private enum CodingKeys: String, CodingKey {
        case id, name, content, senderName = "fullName", senderEmail = "sender", senderEmailIdn = "senderIdn", isDefault, position
    }

    override public var hash: Int {
        id
    }

    override public func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? Self else {
            return false
        }

        return id == object.id
    }
}

public extension Signature {
    /// Appends current signature to an HTML body at correct position
    func appendSignature(to body: String) -> String {
        let html = "\(Constants.editorFirstLines)<div class=\"\(Constants.signatureHTMLClass)\">\(content)</div>"

        var body = body
        switch position {
        case .beforeReplyMessage:
            body.insert(contentsOf: html, at: body.startIndex)
        case .afterReplyMessage:
            body.append(contentsOf: html)
        }

        return body
    }
}

public extension [Signature] {
    /// Find the default signature, if any, in  an `Array` of `Signature`
    var defaultSignature: Signature? {
        return first(where: \.isDefault)
    }

    var defaultReplySignature: Signature? {
        guard let defaultReplySignature = first(where: \.isDefaultReply) else {
            return defaultSignature
        }

        return defaultReplySignature
    }
}

public extension Results<Signature> {
    var defaultSignature: Signature? {
        return first(where: \.isDefault)
    }
}
