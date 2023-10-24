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

// TODO: Move to core

/// Something to help with current running context
public protocol PlatformDetectable {
    /// We are running in Mac Catalyst mode
    var isMacCatalyst: Bool { get }

    /// We are running an iOS App on Mac
    var isiOSAppOnMac: Bool { get }

    /// We are running in extension mode
    var isInExtension: Bool { get }

    /// We are running a debug build
    var isDebug: Bool { get }
}

public struct PlatformDetector: PlatformDetectable {
    public init() {
        // META: Keep SonarCloud happy
    }

    public var isMacCatalyst: Bool = {
        #if targetEnvironment(macCatalyst)
        true
        #else
        false
        #endif
    }()

    public var isiOSAppOnMac: Bool = ProcessInfo().isiOSAppOnMac

    public var isMac: Bool {
        isMacCatalyst || isiOSAppOnMac
    }

    public var isInExtension: Bool = {
        guard Bundle.main.bundlePath.hasSuffix(".appex") else {
            return false
        }

        return true
    }()

    public var isDebug: Bool = {
        #if DEBUG
        true
        #else
        false
        #endif
    }()
}
