//
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
    static func iphoneScreen(group: Int, layer: Int = 1) -> Self {
        return AnimationKeypath(keys: ["IPHONE SCREEN", "Groupe \(group)", "Fond \(layer)"])
    }
}

struct IlluColors {
    let keypath: AnimationKeypath
    let lightColor: String
    let darkColor: String

    // MARK: - Default colors

    static let allColors = [
        IlluColors(keypath: .iphoneScreen(group: 18), lightColor: "#F5F5F5", darkColor: "#3E3E3E"),
        IlluColors(keypath: .iphoneScreen(group: 22), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(keypath: .iphoneScreen(group: 25), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(keypath: .iphoneScreen(group: 26), lightColor: "#FAFAFA", darkColor: "#282828"),
        IlluColors(keypath: .iphoneScreen(group: 27), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(keypath: .iphoneScreen(group: 28), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(keypath: .iphoneScreen(group: 29), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(keypath: .iphoneScreen(group: 30), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(keypath: .iphoneScreen(group: 31), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(keypath: .iphoneScreen(group: 32), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(keypath: .iphoneScreen(group: 33), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(keypath: .iphoneScreen(group: 34), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(keypath: .iphoneScreen(group: 35), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(keypath: .iphoneScreen(group: 36), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(keypath: .iphoneScreen(group: 37), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(keypath: .iphoneScreen(group: 38), lightColor: "#E0E0E0", darkColor: "#4C4C4C"),
        IlluColors(keypath: .iphoneScreen(group: 39), lightColor: "#C6AC9F", darkColor: "#996452"),
        IlluColors(keypath: .iphoneScreen(group: 44), lightColor: "#F5F5F5", darkColor: "#3E3E3E"),
        IlluColors(keypath: .iphoneScreen(group: 49), lightColor: "#C6AC9F", darkColor: "#996452"),
        IlluColors(keypath: .iphoneScreen(group: 50), lightColor: "#F5F5F5", darkColor: "#3E3E3E"),
        IlluColors(keypath: .iphoneScreen(group: 62), lightColor: "#F5F5F5", darkColor: "#3E3E3E"),
        IlluColors(keypath: .iphoneScreen(group: 68), lightColor: "#F5F5F5", darkColor: "#3E3E3E"),
        IlluColors(keypath: .iphoneScreen(group: 70), lightColor: "#F5F5F5", darkColor: "#3E3E3E")
    ]

    // MARK: - Theme colors

    static let pinkColors = [
        IlluColors(keypath: .iphoneScreen(group: 1), lightColor: "#BC0055", darkColor: "#D0759F"),
        IlluColors(keypath: .iphoneScreen(group: 2), lightColor: "#BC0055", darkColor: "#D0759F"),
        IlluColors(keypath: .iphoneScreen(group: 3), lightColor: "#BC0055", darkColor: "#D0759F"),
        IlluColors(keypath: .iphoneScreen(group: 4), lightColor: "#BC0055", darkColor: "#D0759F"),
        IlluColors(keypath: .iphoneScreen(group: 5), lightColor: "#BC0055", darkColor: "#D0759F"),
        IlluColors(keypath: .iphoneScreen(group: 6), lightColor: "#BC0055", darkColor: "#D0759F"),
        IlluColors(keypath: .iphoneScreen(group: 9), lightColor: "#FF5B97", darkColor: "#EF0057"),
        IlluColors(keypath: .iphoneScreen(group: 12), lightColor: "#AB2456", darkColor: "#D0759F"),
        IlluColors(keypath: .iphoneScreen(group: 15), lightColor: "#BC0055", darkColor: "#D0759F"),
        IlluColors(keypath: .iphoneScreen(group: 19), lightColor: "#BC0055", darkColor: "#D0759F"),
        IlluColors(keypath: .iphoneScreen(group: 20), lightColor: "#BC0055", darkColor: "#D0759F"),
        IlluColors(keypath: .iphoneScreen(group: 23), lightColor: "#BC0055", darkColor: "#D0759F"),
        IlluColors(keypath: .iphoneScreen(group: 24), lightColor: "#BC0055", darkColor: "#D0759F"),
        IlluColors(keypath: .iphoneScreen(group: 43), lightColor: "#BD95A7", darkColor: "#AE366D"),
        IlluColors(keypath: .iphoneScreen(group: 48), lightColor: "#BF4C80", darkColor: "#E75F9C")
    ]

    static let blueColors = [
        IlluColors(keypath: .iphoneScreen(group: 1), lightColor: "#0098FF", darkColor: "#0177C7"),
        IlluColors(keypath: .iphoneScreen(group: 2), lightColor: "#0098FF", darkColor: "#0098FF"),
        IlluColors(keypath: .iphoneScreen(group: 3), lightColor: "#0098FF", darkColor: "#0177C7"),
        IlluColors(keypath: .iphoneScreen(group: 4), lightColor: "#0098FF", darkColor: "#0177C7"),
        IlluColors(keypath: .iphoneScreen(group: 5), lightColor: "#0098FF", darkColor: "#0177C7"),
        IlluColors(keypath: .iphoneScreen(group: 6), lightColor: "#0098FF", darkColor: "#0177C7"),
        IlluColors(keypath: .iphoneScreen(group: 9), lightColor: "#69C9FF", darkColor: "#6DCBFF"),
        IlluColors(keypath: .iphoneScreen(group: 12), lightColor: "#0098FF", darkColor: "#0177C7"),
        IlluColors(keypath: .iphoneScreen(group: 15), lightColor: "#0098FF", darkColor: "#0177C7"),
        IlluColors(keypath: .iphoneScreen(group: 19), lightColor: "#0098FF", darkColor: "#0177C7"),
        IlluColors(keypath: .iphoneScreen(group: 20), lightColor: "#0098FF", darkColor: "#0177C7"),
        IlluColors(keypath: .iphoneScreen(group: 23), lightColor: "#0098FF", darkColor: "#0177C7"),
        IlluColors(keypath: .iphoneScreen(group: 24), lightColor: "#0098FF", darkColor: "#0177C7"),
        IlluColors(keypath: .iphoneScreen(group: 43), lightColor: "#3981AA", darkColor: "#56AFE1"),
        IlluColors(keypath: .iphoneScreen(group: 48), lightColor: "#289CDD", darkColor: "#0D7DBC")
    ]
}
