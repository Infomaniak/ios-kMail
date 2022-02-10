//
//  UserDefaults+Extension.swift
//  mail
//
//  Created by Ambroise Decouttere on 08/02/2022.
//

import Foundation

extension UserDefaults {
    static var shared: UserDefaults {
        return UserDefaults(suiteName: "group.com.infomaniak.mail")!
    }

    private enum Keys: String {
        case isUserLoggedIn
    }

    private func key(_ key: Keys) -> String {
        return key.rawValue
    }
}
