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

public protocol LocalContactsHelpable {
    func enumerateContacts(usingBlock: @escaping (CNContact, UnsafeMutablePointer<ObjCBool>) -> Void) async

    func checkAuthorizationAndGetContact(with identifier: String) async throws -> CNContact

    func getContact(with identifier: String) throws -> CNContact
}

public final class LocalContactsHelper: LocalContactsHelpable {
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

    let store = CNContactStore()
    let keysToFetch = ([
        CNContactIdentifierKey,
        CNContactEmailAddressesKey,
        CNContactImageDataAvailableKey,
        CNContactImageDataKey,
        CNContactNicknameKey
    ] as [CNKeyDescriptor]) + [CNContactFormatter.descriptorForRequiredKeys(for: .fullName)]

    public init() {
        // META: Keep SonarCloud happy
    }

    public func enumerateContacts(usingBlock: @escaping (CNContact, UnsafeMutablePointer<ObjCBool>) -> Void) async {
        do {
            try await checkAuthorization()
            let request = CNContactFetchRequest(keysToFetch: keysToFetch)
            try store.enumerateContacts(with: request, usingBlock: usingBlock)
        } catch {
            print("Error while getting contacts: \(error.localizedDescription)")
        }
    }

    public func checkAuthorizationAndGetContact(with identifier: String) async throws -> CNContact {
        try await checkAuthorization()
        return try store.unifiedContact(withIdentifier: identifier, keysToFetch: keysToFetch)
    }

    public func getContact(with identifier: String) throws -> CNContact {
        return try store.unifiedContact(withIdentifier: identifier, keysToFetch: keysToFetch)
    }

    private func checkAuthorization() async throws {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized:
            // All ok
            return
        case .restricted, .denied:
            throw ContactError.accessDenied
        case .notDetermined:
            // Request authorization
            try await store.requestAccess(for: .contacts)
        @unknown default:
            throw ContactError.unhandledCase
        }
    }
}
