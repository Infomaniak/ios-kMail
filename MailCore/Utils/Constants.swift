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
import MailResources
import SwiftUI

public struct URLConstants {
    public static let feedback = URLConstants(urlString: "https://feedback.userreport.com/9f60b46d-7299-4887-b79d-c756cf474c4d#ideas/popular")
    public static let importMails = URLConstants(urlString: "https://import-email.infomaniak.com")
    public static let matomo = URLConstants(urlString: "https://analytics.infomaniak.com/matomo.php")
    public static let support = URLConstants(urlString: "https://support.infomaniak.com")

    private var urlString: String

    public var url: URL {
        guard let url = URL(string: urlString) else {
            fatalError("Invalid URL")
        }
        return url
    }
}

public enum Constants {
    public static let sizeLimit = 20_000_000 // ko

    public static let menuDrawerFolderCellPadding: CGFloat = 4

    static let byteCountFormatter: ByteCountFormatter = {
        let byteCountFormatter = ByteCountFormatter()
        byteCountFormatter.countStyle = .file
        byteCountFormatter.includesUnit = true
        return byteCountFormatter
    }()

    public static func formatQuota(_ size: Int) -> String {
        return Self.byteCountFormatter.string(from: .init(value: Double(size), unit: .kilobytes))
    }
}
