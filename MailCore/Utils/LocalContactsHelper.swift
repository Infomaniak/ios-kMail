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

import Contacts
import Foundation

class LocalContactsHelper {
    enum ContactError: Error, LocalizedError {
        case accessDenied
        case unhandledCase

        var errorDescription: String? {
            switch self {
            case .accessDenied:
                return "Access to contacts is denied"
            case .unhandledCase:
                return "Authorization status case not handled"
            }
        }
    }
    
    static let shared = LocalContactsHelper()

    let store = CNContactStore()
    let keysToFetch = ([CNContactIdentifierKey, CNContactEmailAddressesKey, CNContactImageDataKey, CNContactNicknameKey, CNContactOrganizationNameKey] as [CNKeyDescriptor]) + [CNContactFormatter.descriptorForRequiredKeys(for: .fullName)]

    func enumerateContacts(usingBlock: @escaping (CNContact, UnsafeMutablePointer<ObjCBool>) -> Void) {
        checkAuthorization { error in
            guard error == nil else {
                if let error = error {
                    print("Error while checking authorization status: \(error.localizedDescription)")
                }
                return
            }
            let request = CNContactFetchRequest(keysToFetch: self.keysToFetch)
            do {
                try self.store.enumerateContacts(with: request, usingBlock: usingBlock)
            } catch {
                print("Error while getting contacts: \(error.localizedDescription)")
            }
        }
    }

    func getContact(with identifier: String) async throws -> CNContact {
        _ = try await checkAuthorization()
        return try store.unifiedContact(withIdentifier: identifier, keysToFetch: keysToFetch)
    }

    private func checkAuthorization() async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            checkAuthorization { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: true)
                }
            }
        }
    }

    private func checkAuthorization(completion: @escaping (Error?) -> Void) {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized:
            // All ok
            completion(nil)
        case .restricted, .denied:
            completion(ContactError.accessDenied)
        case .notDetermined:
            // Request authorization
            store.requestAccess(for: .contacts) { granted, error in
                if granted {
                    completion(nil)
                } else {
                    completion(error ?? ContactError.accessDenied)
                }
            }
        @unknown default:
            completion(ContactError.unhandledCase)
        }
    }
}

