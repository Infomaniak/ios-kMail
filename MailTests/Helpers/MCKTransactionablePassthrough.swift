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

import Combine
import Foundation
@testable import Infomaniak_Mail
import InfomaniakCore
import InfomaniakCoreDB
import InfomaniakLogin
@testable import MailCore
@testable import RealmSwift
import XCTest

/// Something that can use an underlying forced unwrapped `transactionExecutor` for testing only
protocol MCKTransactionablePassthrough: Transactionable {
    var transactionExecutor: Transactionable! { get }
}

extension MCKTransactionablePassthrough {
    public func fetchObject<Element: Object, KeyType>(ofType type: Element.Type,
                                                      forPrimaryKey key: KeyType) -> Element? {
        return transactionExecutor.fetchObject(ofType: type, forPrimaryKey: key)
    }

    public func fetchObject<Element: RealmFetchable>(ofType type: Element.Type,
                                                     filtering: (Results<Element>) -> Element?) -> Element? {
        return transactionExecutor.fetchObject(ofType: type, filtering: filtering)
    }

    public func fetchResults<Element: RealmFetchable>(ofType type: Element.Type,
                                                      filtering: (Results<Element>) -> Results<Element>) -> Results<Element> {
        return transactionExecutor.fetchResults(ofType: type, filtering: filtering)
    }

    public func writeTransaction(withRealm realmClosure: (Realm) throws -> Void) throws {
        try transactionExecutor.writeTransaction(withRealm: realmClosure)
    }
}
