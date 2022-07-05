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

import Foundation
import RealmSwift

public enum SignaturePosition: String, PersistableEnum, Decodable {
    case top, bottom
}

public class SignatureResponse: Object, Decodable {
    @Persisted(primaryKey: true) public var id: Int = 1
    @Persisted public var signatures: List<Signature>
    @Persisted public var defaultSignatureId: Int
    @Persisted public var validEmails: List<ValidEmail>
    @Persisted public var position: SignaturePosition

    public var `default`: Signature? {
        return signatures.first(where: \.isDefault)
    }

    private enum CodingKeys: String, CodingKey {
        case signatures, defaultSignatureId, validEmails, position
    }
}

public class Signature: Object, Decodable, Identifiable {
    @Persisted(primaryKey: true) public var id: Int
    @Persisted public var name: String
    @Persisted public var content: String
    @Persisted public var replyTo: String
    @Persisted public var replyToIdn: String
    @Persisted public var replyToId: Int
    @Persisted public var fullName: String
    @Persisted public var sender: String
    @Persisted public var senderIdn: String
    @Persisted public var senderId: Int
    @Persisted public var hashString: String?
    @Persisted public var isDefault: Bool
    @Persisted public var position: SignaturePosition

    private enum CodingKeys: String, CodingKey {
        case id, name, content, replyTo, replyToIdn, replyToId, fullName, sender, senderIdn, senderId, isDefault, position
        // Property 'hash' already exists
        case hashString = "hash"
    }
}

public class ValidEmail: Object, Decodable {
    @Persisted(primaryKey: true) var id: Int
    @Persisted var email: String
    @Persisted var emailIdn: String
    @Persisted var isAccount: Bool
    @Persisted var isVerified: Bool
    @Persisted var isRemovable: Bool
}
