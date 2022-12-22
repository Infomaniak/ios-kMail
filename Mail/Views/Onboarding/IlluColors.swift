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
import Lottie

extension AnimationKeypath {
    enum Category: String {
        case iPhoneScreen = "IPHONE SCREEN"
        case point = "POINT"
        case chat = "CHAT"
        case notification = "NOTIFICATION"
        case movingNotification = "MOVING NOTIF"
        case archives = "ARCHIVES"
        case hand = "HAND"
        case star = "STAR"
        case ben = "BEN"
        case ring = "RING"
        case woman = "WOMAN"
        case men = "MEN"
        case letter = "LETTER"
    }

    enum FinalLayer: String {
        case background = "Fond"
        case border = "Contour"
    }

    static func keyPath(category: Category, numero: Int? = nil, group: Int = 1, finalLayer: FinalLayer = .background) -> Self {
        var categoryName = category.rawValue
        if let numero {
            categoryName = "\(categoryName) \(numero)"
        }
        return AnimationKeypath(keys: [categoryName, "Groupe \(group)", "\(finalLayer.rawValue) 1"])
    }
}

struct IlluColors {
    let keyPath: AnimationKeypath
    let lightColor: String
    let darkColor: String

    init(_ keyPath: AnimationKeypath, lightColor: String, darkColor: String) {
        self.keyPath = keyPath
        self.lightColor = lightColor
        self.darkColor = darkColor
    }

    // MARK: - Default colors

    static let allColors = [
        IlluColors(.keyPath(category: .iPhoneScreen, group: 18), lightColor: "#F5F5F5", darkColor: "#3E3E3E"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 22), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 25), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 26), lightColor: "#FAFAFA", darkColor: "#282828"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 27), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 28), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 29), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 30), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 31), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 32), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 33), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 34), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 35), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 36), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 37), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 38), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 39), lightColor: "#C6AC9F", darkColor: "#996452"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 44), lightColor: "#F5F5F5", darkColor: "#3E3E3E"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 49), lightColor: "#C6AC9F", darkColor: "#996452"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 50), lightColor: "#F5F5F5", darkColor: "#3E3E3E"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 62), lightColor: "#F5F5F5", darkColor: "#3E3E3E"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 68), lightColor: "#F5F5F5", darkColor: "#3E3E3E"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 70), lightColor: "#F5F5F5", darkColor: "#3E3E3E")
    ]

    // MARK: - Theme colors

    static let pinkColors = [
        IlluColors(.keyPath(category: .iPhoneScreen, group: 1), lightColor: "#BC0055", darkColor: "#D0759F"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 2), lightColor: "#BC0055", darkColor: "#D0759F"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 3), lightColor: "#BC0055", darkColor: "#D0759F"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 4), lightColor: "#BC0055", darkColor: "#D0759F"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 5), lightColor: "#BC0055", darkColor: "#D0759F"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 6), lightColor: "#BC0055", darkColor: "#D0759F"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 9), lightColor: "#FF5B97", darkColor: "#EF0057"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 12), lightColor: "#AB2456", darkColor: "#D0759F"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 15), lightColor: "#BC0055", darkColor: "#D0759F"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 19), lightColor: "#BC0055", darkColor: "#D0759F"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 20), lightColor: "#BC0055", darkColor: "#D0759F"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 23), lightColor: "#BC0055", darkColor: "#D0759F"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 24), lightColor: "#BC0055", darkColor: "#D0759F"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 43), lightColor: "#BD95A7", darkColor: "#AE366D"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 48), lightColor: "#BF4C80", darkColor: "#E75F9C")
    ]

    static let blueColors = [
        IlluColors(.keyPath(category: .iPhoneScreen, group: 1), lightColor: "#0098FF", darkColor: "#0177C7"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 2), lightColor: "#0098FF", darkColor: "#0098FF"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 3), lightColor: "#0098FF", darkColor: "#0177C7"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 4), lightColor: "#0098FF", darkColor: "#0177C7"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 5), lightColor: "#0098FF", darkColor: "#0177C7"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 6), lightColor: "#0098FF", darkColor: "#0177C7"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 9), lightColor: "#69C9FF", darkColor: "#6DCBFF"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 12), lightColor: "#0098FF", darkColor: "#0177C7"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 15), lightColor: "#0098FF", darkColor: "#0177C7"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 19), lightColor: "#0098FF", darkColor: "#0177C7"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 20), lightColor: "#0098FF", darkColor: "#0177C7"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 23), lightColor: "#0098FF", darkColor: "#0177C7"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 24), lightColor: "#0098FF", darkColor: "#0177C7"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 43), lightColor: "#3981AA", darkColor: "#56AFE1"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 48), lightColor: "#289CDD", darkColor: "#0D7DBC")
    ]

    // MARK: - Each illustration

    static let illu1Colors = [
        IlluColors(.keyPath(category: .point, numero: 1), lightColor: "#FFFFFF", darkColor: "#1A1A1A"),
        IlluColors(.keyPath(category: .point, numero: 2), lightColor: "#FFFFFF", darkColor: "#1A1A1A"),
        IlluColors(.keyPath(category: .point, numero: 3), lightColor: "#FFFFFF", darkColor: "#1A1A1A"),
        IlluColors(.keyPath(category: .point, numero: 4), lightColor: "#FFFFFF", darkColor: "#1A1A1A"),
        IlluColors(.keyPath(category: .point, numero: 5), lightColor: "#FFFFFF", darkColor: "#1A1A1A"),
        IlluColors(.keyPath(category: .point, numero: 6), lightColor: "#FFFFFF", darkColor: "#1A1A1A"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 56), lightColor: "#F5F5F5", darkColor: "#3E3E3E"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 67), lightColor: "#340E00", darkColor: "#996452"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 69), lightColor: "#FFFFFF", darkColor: "#1A1A1A")
    ]
    static let illu1PinkColors = [
        IlluColors(.keyPath(category: .chat, numero: 1), lightColor: "#BC0055", darkColor: "#D0759F"),
        IlluColors(.keyPath(category: .chat, numero: 2), lightColor: "#BD95A7", darkColor: "#AE366D"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 55), lightColor: "#DFBDCC", darkColor: "#955873"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 61), lightColor: "#BC0055", darkColor: "#D0759F"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 66), lightColor: "#824D65", darkColor: "#AB6685")
    ]
    static let illu1BlueColors = [
        IlluColors(.keyPath(category: .chat, numero: 1), lightColor: "#0098FF", darkColor: "#0177C7"),
        IlluColors(.keyPath(category: .chat, numero: 2), lightColor: "#3981AA", darkColor: "#56AFE1"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 55), lightColor: "#84BAD8", darkColor: "#588EAC"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 61), lightColor: "#0098FF", darkColor: "#0177C7"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 66), lightColor: "#10405B", darkColor: "#10405B")
    ]

    static let illu2Colors = [
        IlluColors(.keyPath(category: .notification, numero: 2, group: 5), lightColor: "#C6AC9F", darkColor: "#996452"),
        IlluColors(.keyPath(category: .notification, numero: 2, group: 6), lightColor: "#F5F5F5", darkColor: "#3E3E3E"),
        IlluColors(.keyPath(category: .notification, numero: 2, group: 9), lightColor: "#CCCCCC", darkColor: "#818181"),
        IlluColors(.keyPath(category: .notification, numero: 2, group: 10), lightColor: "#CCCCCC", darkColor: "#818181"),
        IlluColors(.keyPath(category: .notification, numero: 2, group: 12), lightColor: "#FFFFFF", darkColor: "#1A1A1A"),
        IlluColors(.keyPath(category: .notification, numero: 2, group: 13), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(.keyPath(category: .notification, numero: 2, group: 14), lightColor: "#F5F5F5", darkColor: "#3E3E3E"),
        IlluColors(.keyPath(category: .movingNotification, numero: 1, group: 4), lightColor: "#C4C4C4", darkColor: "#7C7C7C"),
        IlluColors(.keyPath(category: .movingNotification, numero: 1, group: 5), lightColor: "#C4C4C4", darkColor: "#7C7C7C"),
        IlluColors(.keyPath(category: .movingNotification, numero: 1, group: 6), lightColor: "#C4C4C4", darkColor: "#7C7C7C"),
        IlluColors(.keyPath(category: .movingNotification, numero: 1, group: 7), lightColor: "#FFFFFF", darkColor: "#1A1A1A"),
        IlluColors(.keyPath(category: .movingNotification, numero: 1, group: 8), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(.keyPath(category: .movingNotification, numero: 1, group: 9), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(.keyPath(category: .movingNotification, numero: 1, group: 10), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(.keyPath(category: .movingNotification, numero: 1, group: 13), lightColor: "#FFFFFF", darkColor: "#1A1A1A"),
        IlluColors(.keyPath(category: .movingNotification, numero: 1, group: 14), lightColor: "#C4C4C4", darkColor: "#7C7C7C"),
        IlluColors(.keyPath(category: .movingNotification, numero: 2, group: 5), lightColor: "#C6AC9F", darkColor: "#996452"),
        IlluColors(.keyPath(category: .movingNotification, numero: 2, group: 6), lightColor: "#F5F5F5", darkColor: "#3E3E3E"),
        IlluColors(.keyPath(category: .movingNotification, numero: 2, group: 9), lightColor: "#CCCCCC", darkColor: "#818181"),
        IlluColors(.keyPath(category: .movingNotification, numero: 2, group: 10), lightColor: "#CCCCCC", darkColor: "#818181"),
        IlluColors(.keyPath(category: .movingNotification, numero: 2, group: 12), lightColor: "#FFFFFF", darkColor: "#1A1A1A"),
        IlluColors(.keyPath(category: .movingNotification, numero: 2, group: 13), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(.keyPath(category: .movingNotification, numero: 2, group: 14), lightColor: "#F5F5F5", darkColor: "#3E3E3E"),
        IlluColors(.keyPath(category: .movingNotification, numero: 2, group: 15), lightColor: "#F5F5F5", darkColor: "#3E3E3E"),
        IlluColors(AnimationKeypath(keys: ["MOVING NOTIF 2 TITLE", "Groupe 1", "Fond 1"]), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(AnimationKeypath(keys: ["MOVING NOTIF 2 PREVIEW", "Groupe 1", "Fond 1"]), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(.keyPath(category: .archives, group: 1), lightColor: "#FFFFFF", darkColor: "#1A1A1A"),
        IlluColors(.keyPath(category: .archives, group: 2), lightColor: "#FFFFFF", darkColor: "#1A1A1A"),
        IlluColors(.keyPath(category: .archives, group: 3), lightColor: "#FFFFFF", darkColor: "#1A1A1A"),
        IlluColors(.keyPath(category: .archives, group: 4), lightColor: "#FFFFFF", darkColor: "#1A1A1A"),
    ]
    static let illu2PinkColors = [
        IlluColors(.keyPath(category: .notification, numero: 2, group: 4), lightColor: "#BF4C80", darkColor: "#E75F9C"),
        IlluColors(.keyPath(category: .notification, numero: 2, group: 11), lightColor: "#BC0055", darkColor: "#D0759F"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 54), lightColor: "#BF4C80", darkColor: "#E75F9C"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 61), lightColor: "#DFBDCC", darkColor: "#955873"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 67), lightColor: "#BC0055", darkColor: "#D0759F"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 72), lightColor: "#824D65", darkColor: "#AB6685"),
        IlluColors(.keyPath(category: .hand, group: 1), lightColor: "#824D65", darkColor: "#AB6685"),
        IlluColors(.keyPath(category: .hand, group: 4), lightColor: "#693D51", darkColor: "#CA799E"),
        IlluColors(.keyPath(category: .hand, group: 5), lightColor: "#693D51", darkColor: "#CA799E"),
        IlluColors(.keyPath(category: .movingNotification, numero: 1, group: 15), lightColor: "#BC0055", darkColor: "#D0759F"),
        IlluColors(.keyPath(category: .movingNotification, numero: 2, group: 4), lightColor: "#BF4C80", darkColor: "#E75F9C"),
        IlluColors(.keyPath(category: .movingNotification, numero: 2, group: 11), lightColor: "#BC0055", darkColor: "#D0759F")
    ]
    static let illu2BlueColors = [
        IlluColors(.keyPath(category: .notification, numero: 2, group: 4), lightColor: "#289CDD", darkColor: "#0D7DBC"),
        IlluColors(.keyPath(category: .notification, numero: 2, group: 11), lightColor: "#0098FF", darkColor: "#0177C7"),
        IlluColors(.keyPath(category: .hand, group: 1), lightColor: "#10405B", darkColor: "#10405B"),
        IlluColors(.keyPath(category: .hand, group: 4), lightColor: "#0B3547", darkColor: "#266E8D"),
        IlluColors(.keyPath(category: .hand, group: 5), lightColor: "#0B3547", darkColor: "#266E8D"),
        IlluColors(.keyPath(category: .movingNotification, numero: 1, group: 15), lightColor: "#0098FF", darkColor: "#0177C7"),
        IlluColors(.keyPath(category: .movingNotification, numero: 2, group: 4), lightColor: "#289CDD", darkColor: "#0D7DBC"),
        IlluColors(.keyPath(category: .movingNotification, numero: 2, group: 11), lightColor: "#0098FF", darkColor: "#0177C7")
    ]

    static let illu3Colors = [
        IlluColors(.keyPath(category: .notification, numero: 2, group: 1), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(.keyPath(category: .notification, numero: 2, group: 2), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(.keyPath(category: .notification, numero: 2, group: 3), lightColor: "#FFFFFF", darkColor: "#1A1A1A"),
        IlluColors(.keyPath(category: .notification, numero: 3, group: 1), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(.keyPath(category: .notification, numero: 3, group: 2), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(.keyPath(category: .notification, numero: 3, group: 3), lightColor: "#FFFFFF", darkColor: "#1A1A1A"),
        IlluColors(.keyPath(category: .notification, numero: 4, group: 1), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(.keyPath(category: .notification, numero: 4, group: 2), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(.keyPath(category: .notification, numero: 4, group: 3), lightColor: "#FFFFFF", darkColor: "#1A1A1A"),
        IlluColors(.keyPath(category: .star, group: 2), lightColor: "#FAFAFA", darkColor: "#282828"),
        IlluColors(.keyPath(category: .ben, group: 7), lightColor: "#FAFAFA", darkColor: "#282828"),
        IlluColors(.keyPath(category: .ring, group: 5), lightColor: "#FAFAFA", darkColor: "#282828")
    ]
    static let illu3PinkColors = [
        IlluColors(.keyPath(category: .notification, numero: 2, group: 4), lightColor: "#BC0055", darkColor: "#D0759F"),
        IlluColors(.keyPath(category: .notification, numero: 2, group: 5), lightColor: "#F7E8EF", darkColor: "#282828"),
        IlluColors(.keyPath(category: .notification, numero: 3, group: 4), lightColor: "#BC0055", darkColor: "#D0759F"),
        IlluColors(.keyPath(category: .notification, numero: 3, group: 5), lightColor: "#F7E8EF", darkColor: "#282828"),
        IlluColors(.keyPath(category: .notification, numero: 4, group: 4), lightColor: "#BC0055", darkColor: "#D0759F"),
        IlluColors(.keyPath(category: .notification, numero: 4, group: 5), lightColor: "#F7E8EF", darkColor: "#282828"),
        IlluColors(.keyPath(category: .hand, group: 1), lightColor: "#824D65", darkColor: "#AB6685"),
        IlluColors(.keyPath(category: .hand, group: 4), lightColor: "#693D51", darkColor: "#CA799E"),
        IlluColors(.keyPath(category: .hand, group: 4), lightColor: "#693D51", darkColor: "#CA799E"),
        IlluColors(.keyPath(category: .star, group: 1, finalLayer: .border), lightColor: "#BC0055", darkColor: "#D0759F"),
        IlluColors(.keyPath(category: .ben, group: 1, finalLayer: .border), lightColor: "#BC0055", darkColor: "#D0759F"),
        IlluColors(.keyPath(category: .ben, group: 2, finalLayer: .border), lightColor: "#BC0055", darkColor: "#D0759F"),
        IlluColors(.keyPath(category: .ben, group: 3, finalLayer: .border), lightColor: "#BC0055", darkColor: "#D0759F"),
        IlluColors(.keyPath(category: .ben, group: 4, finalLayer: .border), lightColor: "#BC0055", darkColor: "#D0759F"),
        IlluColors(.keyPath(category: .ben, group: 5, finalLayer: .border), lightColor: "#BC0055", darkColor: "#D0759F"),
        IlluColors(.keyPath(category: .ben, group: 6, finalLayer: .border), lightColor: "#BC0055", darkColor: "#D0759F"),
        IlluColors(.keyPath(category: .ring, group: 1), lightColor: "#BC0055", darkColor: "#D0759F"),
        IlluColors(.keyPath(category: .ring, group: 2), lightColor: "#BC0055", darkColor: "#D0759F"),
        IlluColors(.keyPath(category: .ring, group: 3), lightColor: "#BC0055", darkColor: "#D0759F"),
        IlluColors(.keyPath(category: .ring, group: 4), lightColor: "#BC0055", darkColor: "#D0759F")
    ]
    static let illu3BlueColors = [
        IlluColors(.keyPath(category: .notification, numero: 2, group: 4), lightColor: "#0098FF", darkColor: "#0177C7"),
        IlluColors(.keyPath(category: .notification, numero: 2, group: 5), lightColor: "#EAF8FE", darkColor: "#282828"),
        IlluColors(.keyPath(category: .notification, numero: 3, group: 4), lightColor: "#0098FF", darkColor: "#0177C7"),
        IlluColors(.keyPath(category: .notification, numero: 3, group: 5), lightColor: "#EAF8FE", darkColor: "#282828"),
        IlluColors(.keyPath(category: .notification, numero: 4, group: 4), lightColor: "#0098FF", darkColor: "#0177C7"),
        IlluColors(.keyPath(category: .notification, numero: 4, group: 5), lightColor: "#EAF8FE", darkColor: "#282828"),
        IlluColors(.keyPath(category: .hand, group: 1), lightColor: "#10405B", darkColor: "#10405B"),
        IlluColors(.keyPath(category: .hand, group: 4), lightColor: "#0B3547", darkColor: "#266E8D"),
        IlluColors(.keyPath(category: .hand, group: 4), lightColor: "#0B3547", darkColor: "#266E8D"),
        IlluColors(.keyPath(category: .star, group: 1, finalLayer: .border), lightColor: "#0098FF", darkColor: "#0177C7"),
        IlluColors(.keyPath(category: .ben, group: 1, finalLayer: .border), lightColor: "#0098FF", darkColor: "#0177C7"),
        IlluColors(.keyPath(category: .ben, group: 2, finalLayer: .border), lightColor: "#0098FF", darkColor: "#0177C7"),
        IlluColors(.keyPath(category: .ben, group: 3, finalLayer: .border), lightColor: "#0098FF", darkColor: "#0177C7"),
        IlluColors(.keyPath(category: .ben, group: 4, finalLayer: .border), lightColor: "#0098FF", darkColor: "#0177C7"),
        IlluColors(.keyPath(category: .ben, group: 5, finalLayer: .border), lightColor: "#0098FF", darkColor: "#0177C7"),
        IlluColors(.keyPath(category: .ben, group: 6, finalLayer: .border), lightColor: "#0098FF", darkColor: "#0177C7"),
        IlluColors(.keyPath(category: .ring, group: 1), lightColor: "#0098FF", darkColor: "#0177C7"),
        IlluColors(.keyPath(category: .ring, group: 2), lightColor: "#0098FF", darkColor: "#0177C7"),
        IlluColors(.keyPath(category: .ring, group: 3), lightColor: "#0098FF", darkColor: "#0177C7"),
        IlluColors(.keyPath(category: .ring, group: 4), lightColor: "#0098FF", darkColor: "#0177C7")
    ]

    static let illu4Colors = [
        IlluColors(.keyPath(category: .woman, group: 5), lightColor: "#C6AC9F", darkColor: "#996452"),
        IlluColors(.keyPath(category: .woman, group: 6), lightColor: "#F5F5F5", darkColor: "#3E3E3E"),
        IlluColors(.keyPath(category: .men, group: 5), lightColor: "#C6AC9F", darkColor: "#996452"),
        IlluColors(.keyPath(category: .men, group: 6), lightColor: "#F5F5F5", darkColor: "#3E3E3E"),
        IlluColors(.keyPath(category: .letter, group: 3), lightColor: "#FFFFFF", darkColor: "#EAEAEA"),
        IlluColors(.keyPath(category: .letter, group: 4), lightColor: "#F8F8F8", darkColor: "#E4E4E4")
    ]
    static let illu4PinkColors = [
        IlluColors(.keyPath(category: .woman, group: 4), lightColor: "#BF4C80", darkColor: "#E75F9C"),
        IlluColors(.keyPath(category: .men, group: 5), lightColor: "#BD95A7", darkColor: "#AE366D"),
        IlluColors(.keyPath(category: .point, numero: 1), lightColor: "#BF4C80", darkColor: "#E75F9C"),
        IlluColors(.keyPath(category: .point, numero: 2), lightColor: "#BF4C80", darkColor: "#E75F9C"),
        IlluColors(.keyPath(category: .point, numero: 3), lightColor: "#BD95A7", darkColor: "#AE366D"),
        IlluColors(.keyPath(category: .point, numero: 4), lightColor: "#BD95A7", darkColor: "#AE366D"),
        IlluColors(.keyPath(category: .letter, group: 1), lightColor: "#FF4388", darkColor: "#B80043"),
        IlluColors(.keyPath(category: .letter, group: 2), lightColor: "#D81B60", darkColor: "#FB2C77"),
        IlluColors(.keyPath(category: .letter, group: 5), lightColor: "#FAF0F0", darkColor: "#F1DDDD"),
        IlluColors(.keyPath(category: .letter, group: 6), lightColor: "#E10B59", darkColor: "#DC1A60"),
        IlluColors(.keyPath(category: .letter, group: 7), lightColor: "#E10B59", darkColor: "#DC1A60")
    ]
    static let illu4BlueColors = [
        IlluColors(.keyPath(category: .woman, group: 4), lightColor: "#289CDD", darkColor: "#0D7DBC"),
        IlluColors(.keyPath(category: .men, group: 5), lightColor: "#3981AA", darkColor: "#56AFE1"),
        IlluColors(.keyPath(category: .point, numero: 1), lightColor: "#289CDD", darkColor: "#0D7DBC"),
        IlluColors(.keyPath(category: .point, numero: 2), lightColor: "#289CDD", darkColor: "#0D7DBC"),
        IlluColors(.keyPath(category: .point, numero: 3), lightColor: "#3981AA", darkColor: "#56AFE1"),
        IlluColors(.keyPath(category: .point, numero: 4), lightColor: "#3981AA", darkColor: "#56AFE1"),
        IlluColors(.keyPath(category: .letter, group: 1), lightColor: "#FF4388", darkColor: "#6DCBFF"),
        IlluColors(.keyPath(category: .letter, group: 2), lightColor: "#D81B60", darkColor: "#0A85C9"),
        IlluColors(.keyPath(category: .letter, group: 5), lightColor: "#FAF0F0", darkColor: "#E8F6FF"),
        IlluColors(.keyPath(category: .letter, group: 6), lightColor: "#E10B59", darkColor: "#0875A5"),
        IlluColors(.keyPath(category: .letter, group: 7), lightColor: "#E10B59", darkColor: "#0875A5")
    ]

    // MARK: - Several illustrations

    static let illu234Colors = [
        IlluColors(.keyPath(category: .iPhoneScreen, group: 73), lightColor: "#340E00", darkColor: "#996452"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 74), lightColor: "#F5F5F5", darkColor: "#3E3E3E"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 75), lightColor: "#FFFFFF", darkColor: "#1A1A1A"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 76), lightColor: "#E0E0E0", darkColor: "#4C4C4C")
    ]
    static let illu234PinkColors = [
        IlluColors(.keyPath(category: .iPhoneScreen, group: 54), lightColor: "#BF4C80", darkColor: "#E75F9C"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 61), lightColor: "#DFBDCC", darkColor: "#955873"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 67), lightColor: "#BC0055", darkColor: "#D0759F"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 72), lightColor: "#824D65", darkColor: "#AB6685")
    ]
    static let illu234BlueColors = [
        IlluColors(.keyPath(category: .iPhoneScreen, group: 54), lightColor: "#289CDD", darkColor: "#3E3E3E"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 61), lightColor: "#84BAD8", darkColor: "#588EAC"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 67), lightColor: "#0098FF", darkColor: "#0177C7"),
        IlluColors(.keyPath(category: .iPhoneScreen, group: 72), lightColor: "#10405B", darkColor: "#10405B")
    ]
}
