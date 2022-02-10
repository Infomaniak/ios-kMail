//
//  Account.swift
//  mail
//
//  Created by Ambroise Decouttere on 08/02/2022.
//

import Foundation
import InfomaniakLogin

open class Account: Codable {
    public var token: ApiToken! {
        didSet {
            if let token = token {
                userId = token.userId
            }
        }
    }

    public var userId: Int

    public init(apiToken: ApiToken) {
        self.token = apiToken
        self.userId = apiToken.userId
    }
}
