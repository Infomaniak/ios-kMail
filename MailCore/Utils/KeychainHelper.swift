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
import Foundation
import InfomaniakCore
import Sentry

public class KeychainHelper {
    private let accessGroup = AccountManager.accessGroup
    private let tag = "ch.infomaniak.token".data(using: .utf8)!
    private let keychainQueue = DispatchQueue(label: "com.infomaniak.keychain")

    private let lockedKey = "isLockedKey"
    private let lockedValue = "locked".data(using: .utf8)!
    private var accessibilityValueWritten = false

    public init() {}

    var isKeychainAccessible: Bool {
        if !accessibilityValueWritten {
            initKeychainAccessibility()
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: lockedKey,
            kSecAttrAccessGroup as String: accessGroup,
            kSecReturnData as String: kCFBooleanTrue as Any,
            kSecReturnAttributes as String: kCFBooleanTrue as Any,
            kSecReturnRef as String: kCFBooleanTrue as Any,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]

        var result: AnyObject?

        let resultCode = withUnsafeMutablePointer(to: &result) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }

        if resultCode == noErr, let array = result as? [[String: Any]] {
            for item in array {
                if let value = item[kSecValueData as String] as? Data {
                    return value == lockedValue
                }
            }
            return false
        } else {
            DDLogInfo("[Keychain] Accessible error ? \(resultCode == noErr), \(resultCode)")
            return false
        }
    }

    private func initKeychainAccessibility() {
        accessibilityValueWritten = true
        let queryAdd: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccessGroup as String: accessGroup,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            kSecAttrService as String: lockedKey,
            kSecValueData as String: lockedValue
        ]
        let resultCode = SecItemAdd(queryAdd as CFDictionary, nil)
        DDLogInfo(
            "[Keychain] Successfully init KeychainHelper ? \(resultCode == noErr || resultCode == errSecDuplicateItem), \(resultCode)"
        )
    }

    public func deleteToken(for userId: Int) {
        keychainQueue.sync {
            let queryDelete: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: tag,
                kSecAttrAccount as String: "\(userId)"
            ]
            let resultCode = SecItemDelete(queryDelete as CFDictionary)
            DDLogInfo("Successfully deleted token ? \(resultCode == noErr)")
        }
    }

    public func storeToken(_ token: ApiToken) {
        var resultCode: OSStatus = noErr
        // swiftlint:disable force_try
        let tokenData = try! JSONEncoder().encode(token)

        if let savedToken = getSavedToken(for: token.userId) {
            keychainQueue.sync {
                // Save token only if it's more recent
                if savedToken.expirationDate <= token.expirationDate {
                    let queryUpdate: [String: Any] = [
                        kSecClass as String: kSecClassGenericPassword,
                        kSecAttrAccount as String: "\(token.userId)"
                    ]

                    let attributes: [String: Any] = [
                        kSecValueData as String: tokenData
                    ]
                    resultCode = SecItemUpdate(queryUpdate as CFDictionary, attributes as CFDictionary)
                    DDLogInfo("Successfully updated token ? \(resultCode == noErr)")
                    SentrySDK.addBreadcrumb(crumb: token.generateBreadcrumb(level: .info, message: "Successfully updated token"))
                }
            }
        } else {
            deleteToken(for: token.userId)
            keychainQueue.sync {
                let queryAdd: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrAccessGroup as String: accessGroup,
                    kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
                    kSecAttrService as String: tag,
                    kSecAttrAccount as String: "\(token.userId)",
                    kSecValueData as String: tokenData
                ]
                resultCode = SecItemAdd(queryAdd as CFDictionary, nil)
                DDLogInfo("Successfully saved token ? \(resultCode == noErr)")
                SentrySDK.addBreadcrumb(crumb: token.generateBreadcrumb(level: .info, message: "Successfully saved token"))
            }
        }
        if resultCode != noErr {
            SentrySDK
                .addBreadcrumb(crumb: token
                    .generateBreadcrumb(level: .error, message: "Failed saving token", keychainError: resultCode))
        }
    }

    public func getSavedToken(for userId: Int) -> ApiToken? {
        var savedToken: ApiToken?
        keychainQueue.sync {
            let queryFindOne: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: tag,
                kSecAttrAccessGroup as String: accessGroup,
                kSecAttrAccount as String: "\(userId)",
                kSecReturnData as String: kCFBooleanTrue as Any,
                kSecReturnAttributes as String: kCFBooleanTrue as Any,
                kSecReturnRef as String: kCFBooleanTrue as Any,
                kSecMatchLimit as String: kSecMatchLimitOne
            ]
            var result: AnyObject?

            let resultCode = withUnsafeMutablePointer(to: &result) {
                SecItemCopyMatching(queryFindOne as CFDictionary, UnsafeMutablePointer($0))
            }

            let jsonDecoder = JSONDecoder()
            if resultCode == noErr,
               let keychainItem = result as? [String: Any],
               let value = keychainItem[kSecValueData as String] as? Data,
               let token = try? jsonDecoder.decode(ApiToken.self, from: value) {
                savedToken = token
            }
        }
        return savedToken
    }

    public func loadTokens() -> [ApiToken] {
        var values = [ApiToken]()
        keychainQueue.sync {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: tag,
                kSecAttrAccessGroup as String: accessGroup,
                kSecReturnData as String: kCFBooleanTrue as Any,
                kSecReturnAttributes as String: kCFBooleanTrue as Any,
                kSecReturnRef as String: kCFBooleanTrue as Any,
                kSecMatchLimit as String: kSecMatchLimitAll
            ]

            var result: AnyObject?

            let resultCode = withUnsafeMutablePointer(to: &result) {
                SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
            }
            DDLogInfo("Successfully loaded tokens ? \(resultCode == noErr)")

            if resultCode == noErr {
                let jsonDecoder = JSONDecoder()
                if let array = result as? [[String: Any]] {
                    for item in array {
                        if let value = item[kSecValueData as String] as? Data {
                            if let token = try? jsonDecoder.decode(ApiToken.self, from: value) {
                                values.append(token)
                            }
                        }
                    }
                    if let token = values.first {
                        SentrySDK
                            .addBreadcrumb(crumb: token.generateBreadcrumb(level: .info, message: "Successfully loaded token"))
                    }
                }
            } else {
                let crumb = Breadcrumb(level: .error, category: "Token")
                crumb.type = "error"
                crumb.message = "Failed loading tokens"
                crumb.data = ["Keychain error code": resultCode]
                SentrySDK.addBreadcrumb(crumb: crumb)
            }
        }
        return values
    }
}
