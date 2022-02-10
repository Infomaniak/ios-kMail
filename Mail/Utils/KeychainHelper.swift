//
//  KeychainHelper.swift
//  mail
//
//  Created by Ambroise Decouttere on 08/02/2022.
//

import Foundation
import InfomaniakLogin

public enum KeychainHelper {
    private static let tag = "ch.infomaniak.token".data(using: .utf8)!
    private static let keychainQueue = DispatchQueue(label: "com.infomaniak.mail.keychain")

    public static func deleteToken(for userId: Int) {
        keychainQueue.sync {
            let queryDelete: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: tag,
                kSecAttrAccount as String: "\(userId)"
            ]
            _ = SecItemDelete(queryDelete as CFDictionary)
        }
    }

    public static func storeToken(_ token: ApiToken) {
        var resultCode: OSStatus = noErr
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
                }
            }
        } else {
            deleteToken(for: token.userId)
            keychainQueue.sync {
                let queryAdd: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
                    kSecAttrService as String: tag,
                    kSecAttrAccount as String: "\(token.userId)",
                    kSecValueData as String: tokenData
                ]
                resultCode = SecItemAdd(queryAdd as CFDictionary, nil)
            }
        }
    }

    public static func getSavedToken(for userId: Int) -> ApiToken? {
        var savedToken: ApiToken?
        keychainQueue.sync {
            let queryFindOne: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: tag,
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

    public static func loadTokens() -> [ApiToken] {
        var values = [ApiToken]()
        keychainQueue.sync {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: tag,
                kSecReturnData as String: kCFBooleanTrue as Any,
                kSecReturnAttributes as String: kCFBooleanTrue as Any,
                kSecReturnRef as String: kCFBooleanTrue as Any,
                kSecMatchLimit as String: kSecMatchLimitAll
            ]

            var result: AnyObject?

            let resultCode = withUnsafeMutablePointer(to: &result) {
                SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
            }

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
                }
            }
        }
        return values
    }
}
